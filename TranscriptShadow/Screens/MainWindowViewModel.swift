// @implements SCR-001, SCR-003, SCR-004, UJ-001
// State machine for the main window: swaps between pre-flight (SCR-001),
// processing (SCR-003 — with optional audio URL fed to the pipeline),
// and transcript (SCR-004). Owns the link to the shared
// `RecordingHUDController` so Record triggers the HUD via BR-501.
//
// `handleRecord()` requests mic permission, runs the system-audio
// fallback (RISK-004 mitigation), starts `AudioCaptureService`, then
// reassigns `hud.onStop` to a closure that calls `stopCapture()` and
// transitions to `.processing(audioURL:)` so SCR-003 can run the
// pipeline. The demo HUD flows (Cmd+4..6) keep the init-time onStop
// closure which transitions to `.processing(audioURL: nil)` and leaves
// the canned mock stages visible.

import Combine
import Foundation

enum MainContent: Equatable {
    case preFlight
    case processing(audioURL: URL?)
    case transcript(id: String)
}

@MainActor
final class MainWindowViewModel: ObservableObject {
    @Published var content: MainContent = .preFlight
    @Published var selectedTranscriptID: String? = nil
    @Published var showSettings: Bool = false
    @Published var recordError: String?
    /// Set when system-audio permission is missing but the user chose to
    /// proceed mic-only. Cleared on next Record.
    @Published var systemAudioFellBack: Bool = false
    /// Set when a transcript saved but its auto-export to Obsidian failed
    /// (F-1). Surfaced as a dismissible window banner; cleared on the next
    /// Record or navigation.
    @Published var exportWarning: String?

    let env: AppEnvironment
    let hud: RecordingHUDController
    let permissions: PermissionsCoordinator
    let sidebarVM: SidebarViewModel

    init(env: AppEnvironment, hud: RecordingHUDController = .shared, permissions: PermissionsCoordinator = .init()) {
        self.env = env
        self.hud = hud
        self.permissions = permissions
        self.sidebarVM = SidebarViewModel(env: env)
        #if DEBUG
        // Default onStop is the demo-flow handler — transitions to canned
        // `processing` without an audioURL. handleRecord replaces this for the
        // real-recording path. DEBUG only (F-2): no demo entry points ship in
        // Release, so the real handler handleRecord installs is the only
        // onStop a shipped build ever uses.
        hud.onStop = { [weak self] in
            self?.content = .processing(audioURL: nil)
        }
        #endif
    }

    // MARK: - Intent

    /// Real Record button. Checks mic permission, runs the system-audio
    /// fallback, then starts capture and shows the HUD. The HUD's Stop
    /// callback (installed below) calls `stopCapture()` and transitions
    /// the main window into SCR-003 with the captured WAV URL.
    func handleRecord() async {
        recordError = nil
        systemAudioFellBack = false
        exportWarning = nil

        let mic = permissions.microphoneStatus
        let micResolved: PermissionsCoordinator.Status
        if mic == .notDetermined {
            micResolved = await permissions.requestMicrophone()
        } else {
            micResolved = mic
        }
        if micResolved != .granted {
            recordError = "Microphone access is required. Enable it in System Settings."
            return
        }

        let wantsMic = (try? await env.settings.read(.captureMicrophone)) ?? true
        let wantsSystem = (try? await env.settings.read(.captureSystemAudio)) ?? true
        var useSystem = wantsSystem
        if wantsSystem && permissions.screenRecordingStatus != .granted {
            // RISK-004 mitigation: fall back to mic-only and surface a
            // banner so the user can grant + relaunch later.
            useSystem = false
            systemAudioFellBack = true
        }
        if !wantsMic && !useSystem {
            recordError = "Turn on at least one source (microphone or system audio)."
            return
        }
        let config = AudioCaptureConfiguration(
            captureMicrophone: wantsMic,
            captureSystemAudio: useSystem
        )
        do {
            try await env.audioCapture.startCapture(configuration: config)
        } catch {
            recordError = "Couldn't start recording: \(error.localizedDescription)"
            return
        }

        // Replace the demo onStop with a real one that drains the
        // capture and routes the URL into SCR-003.
        hud.onStop = { [weak self] in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let url = try await self.env.audioCapture.stopCapture()
                    self.content = .processing(audioURL: url)
                } catch {
                    self.recordError = "Couldn't stop recording cleanly: \(error.localizedDescription)"
                    self.content = .preFlight
                }
                #if DEBUG
                // Restore the demo onStop so a subsequent Cmd+4..6 demo
                // starts fresh without a stale URL flow.
                self.hud.onStop = { [weak self] in
                    self?.content = .processing(audioURL: nil)
                }
                #else
                // No demo flow in Release — clear onStop so a stray Stop is a
                // no-op; the next handleRecord() installs a fresh real handler.
                self.hud.onStop = nil
                #endif
            }
        }
        hud.forcedRealization = nil
        hud.startRecording()
    }

    func openSettings() { showSettings = true }
    func closeSettings() { showSettings = false }

    func selectTranscript(id: String?) {
        selectedTranscriptID = id
        if let id { content = .transcript(id: id) }
    }

    func goToPreFlight() { content = .preFlight; selectedTranscriptID = nil; exportWarning = nil }
    #if DEBUG
    // Demo nav only (Cmd+2) — routes to canned processing with no audio.
    func goToProcessing() { content = .processing(audioURL: nil); selectedTranscriptID = nil }
    #endif

    func onPipelineComplete(transcriptID: UUID, exportWarning: String? = nil) {
        self.exportWarning = exportWarning
        selectTranscript(id: transcriptID.uuidString)
        // Codex Gate 5b P2 fix — SCR-006 sidebar would otherwise stay
        // stale until next launch. Trigger a fresh
        // TranscriptStore.list so the new row shows up.
        Task { @MainActor [sidebarVM] in await sidebarVM.load() }
    }
}
