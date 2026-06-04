// @implements SCR-001 (host shell), SCR-003, SCR-004 (content states)
// @see SoT/SoT.USER_JOURNEYS.md
// @see design/visual-prototype/project/src/scr00{1,3,4}.jsx
//
// The main window is sidebar + content. The content swaps between three
// states: pre-flight (SCR-001), processing (SCR-003), transcript (SCR-004).
// Per BR-501, when recording is active, this entire window hides and the
// Recording HUD (DES-105/DES-106) takes over.

import SwiftUI

struct MainWindowView: View {
    let env: AppEnvironment
    @StateObject private var vm: MainWindowViewModel
    @ObservedObject private var hud = RecordingHUDController.shared

    init(env: AppEnvironment) {
        self.env = env
        _vm = StateObject(wrappedValue: MainWindowViewModel(env: env))
    }

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(vm: vm.sidebarVM, selectedID: Binding(
                get: { vm.selectedTranscriptID },
                set: { vm.selectTranscript(id: $0) }
            ))
            contentArea
        }
        .frame(minWidth: DesignSpacing.Layout.windowMinWidth,
               minHeight: DesignSpacing.Layout.windowMinHeight)
        .background(DesignColors.bgPrimary)
        .background(WindowAccessor { window in
            hud.mainWindow = window
        })
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { vm.openSettings() }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                }
                .help("Settings (⌘,)")
            }
        }
        .sheet(isPresented: Binding(get: { vm.showSettings }, set: { vm.showSettings = $0 })) {
            SettingsView(env: env)
        }
        // F-1: non-fatal auto-export failure surfaces as a dismissible banner.
        .overlay(alignment: .top) {
            if let warning = vm.exportWarning {
                exportWarningBanner(warning)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
            }
        }
        // Settings (⌘,) — real, always present.
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            vm.openSettings()
        }
        #if DEBUG
        // Demo navigation (Cmd+1..6) — DEBUG only (F-2). The Demo menu that
        // posts these is itself #if DEBUG, so none of this ships in Release.
        .onReceive(NotificationCenter.default.publisher(for: .demoNavPreFlight)) { _ in
            vm.goToPreFlight()
        }
        .onReceive(NotificationCenter.default.publisher(for: .demoNavProcessing)) { _ in
            vm.goToProcessing()
        }
        .onReceive(NotificationCenter.default.publisher(for: .demoNavTranscript)) { _ in
            vm.selectTranscript(id: "t1")
        }
        .onReceive(NotificationCenter.default.publisher(for: .demoStartRecording)) { _ in
            hud.startRecording()
        }
        .onReceive(NotificationCenter.default.publisher(for: .demoForceNotchHUD)) { _ in
            hud.forcedRealization = .notch
            hud.startRecording()
        }
        .onReceive(NotificationCenter.default.publisher(for: .demoForceMenuBarHUD)) { _ in
            hud.forcedRealization = .menuBar
            hud.startRecording()
        }
        #endif
    }

    @ViewBuilder
    private var contentArea: some View {
        switch vm.content {
        case .preFlight:
            PreFlightContent(
                env: env,
                onRecord: { Task { @MainActor in await vm.handleRecord() } },
                errorMessage: vm.recordError,
                systemAudioWarning: vm.systemAudioFellBack
            )
        case .processing(let url):
            ProcessingView(
                env: env,
                audioURL: url,
                onCancel: { vm.goToPreFlight() },
                onComplete: { id, warning in vm.onPipelineComplete(transcriptID: id, exportWarning: warning) }
            )
        case .transcript(let id):
            TranscriptView(env: env, transcriptID: id)
                .id(id)
        }
    }

    // F-1: dismissible banner for a non-fatal auto-export failure. Matches the
    // PreFlightContent banner style. The transcript is already saved, so this
    // warns rather than blocks.
    private func exportWarningBanner(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(DesignColors.Status.warning).frame(width: 6, height: 6)
                .padding(.top, 5)
            Text(text)
                .font(DesignFonts.ui(11.5))
                .foregroundStyle(DesignColors.Status.warning)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button {
                vm.exportWarning = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(DesignColors.Status.warning)
            }
            .buttonStyle(.plain)
            .help("Dismiss")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(DesignColors.Status.warning.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(DesignColors.Status.warning.opacity(0.5), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: 560)
    }
}

// MARK: - Demo navigation (temporary; remove when EPIC-08 wires real state)

extension Notification.Name {
    static let openSettings = Notification.Name("ShadowTranscript.openSettings")
    #if DEBUG
    static let demoNavPreFlight = Notification.Name("ShadowTranscript.demoNavPreFlight")
    static let demoNavProcessing = Notification.Name("ShadowTranscript.demoNavProcessing")
    static let demoNavTranscript = Notification.Name("ShadowTranscript.demoNavTranscript")
    static let demoStartRecording = Notification.Name("ShadowTranscript.demoStartRecording")
    static let demoForceNotchHUD = Notification.Name("ShadowTranscript.demoForceNotchHUD")
    static let demoForceMenuBarHUD = Notification.Name("ShadowTranscript.demoForceMenuBarHUD")
    #endif
}

#Preview("Pre-flight") {
    MainWindowView(env: .preview())
        .frame(width: 1100, height: 700)
}
