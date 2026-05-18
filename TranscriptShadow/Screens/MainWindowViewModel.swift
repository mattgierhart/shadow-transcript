// @implements SCR-001, SCR-003, SCR-004
// State machine for the main window: swaps between pre-flight (SCR-001),
// processing (SCR-003), and transcript (SCR-004). Owns the link to the
// shared `RecordingHUDController` so Record triggers the HUD via BR-501.
//
// Phase 1 scope: scaffolding only — `handleRecord()` still uses the
// existing demo path. Phase 3 replaces it with real `AudioCaptureService`
// calls + permission checks.

import Combine
import Foundation

enum MainContent: Equatable {
    case preFlight
    case processing
    case transcript(id: String)
}

@MainActor
final class MainWindowViewModel: ObservableObject {
    @Published var content: MainContent = .preFlight
    @Published var selectedTranscriptID: String? = nil
    @Published var showSettings: Bool = false

    let env: AppEnvironment
    let hud: RecordingHUDController

    init(env: AppEnvironment, hud: RecordingHUDController = .shared) {
        self.env = env
        self.hud = hud
        hud.onStop = { [weak self] in
            self?.content = .processing
        }
    }

    // MARK: - Intent

    /// User clicked the Record button. Phase 3 will add permission checks
    /// and wire `AudioCaptureService.startCapture`; today this still goes
    /// through the demo path (HUD shows, main window hides, Stop returns to
    /// processing).
    func handleRecord() {
        hud.forcedRealization = nil
        hud.startRecording()
    }

    func openSettings() { showSettings = true }
    func closeSettings() { showSettings = false }

    func selectTranscript(id: String?) {
        selectedTranscriptID = id
        if let id { content = .transcript(id: id) }
    }

    func goToPreFlight() { content = .preFlight; selectedTranscriptID = nil }
    func goToProcessing() { content = .processing; selectedTranscriptID = nil }
}
