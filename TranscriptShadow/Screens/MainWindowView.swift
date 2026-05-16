// @implements SCR-001 (Main Window — Idle / Pre-Record), UJ-001 step 1-3
// @see SoT/SoT.USER_JOURNEYS.md SCR-001
// @see design/visual-prototype/project/src/scr001.jsx :: ScreenSCR001
//
// Pre-flight surface: source toggles + level preview + start-only Record.
// Per BR-501, this window hides on Record (HUD takes over). The hide/restore
// transition is wired in EPIC-08's pipeline orchestrator — this file owns the
// visual only.

import SwiftUI

struct MainWindowView: View {
    @State private var selectedTranscriptID: String? = nil
    @State private var micEnabled: Bool = true
    @State private var systemAudioEnabled: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(selectedID: $selectedTranscriptID)
            contentArea
        }
        .frame(minWidth: DesignSpacing.Layout.windowMinWidth,
               minHeight: DesignSpacing.Layout.windowMinHeight)
        .background(DesignColors.bgPrimary)
        .preferredColorScheme(.dark)
    }

    private var contentArea: some View {
        ZStack {
            // Subtle ambient teal glow (matches JSX radial gradient)
            RadialGradient(
                colors: [DesignColors.accentPrimary.opacity(0.05), .clear],
                center: .init(x: 0.5, y: 0.38),
                startRadius: 0,
                endRadius: 400
            )
            .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 32) {
                    statusPill
                    sourceToggles
                    AudioLevelPreview()
                    RecordButton(action: handleRecord)
                        .padding(.top, 8)
                    lastRecordingFootnote
                }
                .frame(maxWidth: DesignSpacing.Spacious.contentMaxWidth)
                .padding(48)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Pieces

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(DesignColors.Status.success)
                .frame(width: 6, height: 6)
            Text("Ready · all processing stays on this Mac")
                .font(DesignFonts.mono(11))
                .foregroundStyle(DesignColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(DesignColors.bgSecondary)
        .overlay(
            Capsule().stroke(DesignColors.borderDefault, lineWidth: 0.5)
        )
        .clipShape(Capsule())
    }

    private var sourceToggles: some View {
        HStack(spacing: 12) {
            SourceToggle(
                systemIcon: "mic.fill",
                label: "Microphone",
                sub: "MacBook Pro Microphone",
                isOn: $micEnabled
            )
            SourceToggle(
                systemIcon: "speaker.wave.2.fill",
                label: "System audio",
                sub: "ScreenCaptureKit · all apps",
                isOn: $systemAudioEnabled
            )
        }
    }

    private var lastRecordingFootnote: some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(DesignColors.borderDefault)
                .frame(height: 0.5)

            HStack(spacing: 6) {
                Text("Last:")
                    .foregroundStyle(DesignColors.textSecondary)
                Text("Q3 Planning · Eng + Design")
                    .foregroundStyle(DesignColors.textPrimary)
                Text("· 32 min ago")
                    .foregroundStyle(DesignColors.textMuted)
            }
            .font(DesignFonts.ui(11.5))
        }
    }

    // MARK: - Actions

    private func handleRecord() {
        // EPIC-08 will wire this to AudioCaptureService.startCapture +
        // the hide-main-window / show-HUD transition. For the UI shell,
        // we just print so the keystroke + click prove the hookup is live.
        print("[SCR-001] Record clicked. EPIC-08 will hide main + show DES-105/106 HUD.")
    }
}

#Preview {
    MainWindowView()
        .frame(width: 1100, height: 700)
}
