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

enum MainContent: Equatable {
    case preFlight
    case processing
    case transcript(id: String)
}

struct MainWindowView: View {
    @State private var content: MainContent = .preFlight
    @State private var selectedTranscriptID: String? = nil
    @State private var showSettings: Bool = false
    @ObservedObject private var hud = RecordingHUDController.shared

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(selectedID: $selectedTranscriptID)
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
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                }
                .help("Settings (⌘,)")
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onAppear {
            // When Stop is tapped on the HUD, restore the main window into
            // the processing view (SCR-003). Real audio pipeline is EPIC-08.
            hud.onStop = { content = .processing }
        }
        .onChange(of: selectedTranscriptID) { _, newValue in
            if let id = newValue {
                content = .transcript(id: id)
            }
        }
        .onChange(of: content) { _, newValue in
            // Returning to pre-flight or processing clears the sidebar
            // highlight so the next click reads as a fresh selection.
            if case .preFlight = newValue { selectedTranscriptID = nil }
            if case .processing = newValue { selectedTranscriptID = nil }
        }
        // Demo navigation — temporary until EPIC-08 wires real state.
        .onReceive(NotificationCenter.default.publisher(for: .demoNavPreFlight)) { _ in
            content = .preFlight
        }
        .onReceive(NotificationCenter.default.publisher(for: .demoNavProcessing)) { _ in
            content = .processing
        }
        .onReceive(NotificationCenter.default.publisher(for: .demoNavTranscript)) { _ in
            selectedTranscriptID = "t1"
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            showSettings = true
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
        switch content {
        case .preFlight:
            PreFlightContent(onRecord: handleRecord)
        case .processing:
            ProcessingView(onCancel: { content = .preFlight })
        case .transcript:
            TranscriptView()
        }
    }

    // MARK: - Actions

    private func handleRecord() {
        // Per BR-501 — hide the main window and show the HUD.
        // The HUD's Stop callback (set in onAppear) flips content to
        // .processing and restores the window. Real audio capture is EPIC-08.
        hud.forcedRealization = nil  // auto-detect notch
        hud.startRecording()
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
    MainWindowView()
        .frame(width: 1100, height: 700)
}
