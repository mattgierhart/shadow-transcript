// @implements SCR-001 (host shell), SCR-003, SCR-004 (content states)
// @see SoT/SoT.USER_JOURNEYS.md
// @see design/visual-prototype/project/src/scr00{1,3,4}.jsx
//
// The main window is sidebar + content. The content swaps between three
// states: pre-flight (SCR-001), processing (SCR-003), transcript (SCR-004).
// Per BR-501, when recording is active, this entire window hides and the
// Recording HUD (DES-105/DES-106) takes over — that wiring is EPIC-08's
// pipeline-orchestrator scope and not implemented here yet.

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
            Sidebar(env: env, selectedID: Binding(
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
        // Demo navigation — temporary until EPIC-08 wires real state.
        .onReceive(NotificationCenter.default.publisher(for: .demoNavPreFlight)) { _ in
            vm.goToPreFlight()
        }
        .onReceive(NotificationCenter.default.publisher(for: .demoNavProcessing)) { _ in
            vm.goToProcessing()
        }
        .onReceive(NotificationCenter.default.publisher(for: .demoNavTranscript)) { _ in
            vm.selectTranscript(id: "t1")
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            vm.openSettings()
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
    }

    @ViewBuilder
    private var contentArea: some View {
        switch vm.content {
        case .preFlight:
            PreFlightContent(env: env, onRecord: { vm.handleRecord() })
        case .processing:
            ProcessingView(env: env, onCancel: { vm.goToPreFlight() })
        case .transcript:
            TranscriptView(env: env)
        }
    }
}

// MARK: - Demo navigation (temporary; remove when EPIC-08 wires real state)

extension Notification.Name {
    static let demoNavPreFlight = Notification.Name("ShadowTranscript.demoNavPreFlight")
    static let demoNavProcessing = Notification.Name("ShadowTranscript.demoNavProcessing")
    static let demoNavTranscript = Notification.Name("ShadowTranscript.demoNavTranscript")
    static let openSettings = Notification.Name("ShadowTranscript.openSettings")
    static let demoStartRecording = Notification.Name("ShadowTranscript.demoStartRecording")
    static let demoForceNotchHUD = Notification.Name("ShadowTranscript.demoForceNotchHUD")
    static let demoForceMenuBarHUD = Notification.Name("ShadowTranscript.demoForceMenuBarHUD")
}

#Preview("Pre-flight") {
    MainWindowView(env: .preview())
        .frame(width: 1100, height: 700)
}
