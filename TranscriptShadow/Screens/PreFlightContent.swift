// @implements SCR-001 content area
// Extracted from MainWindowView so the main window can swap its content
// between SCR-001 (pre-flight), SCR-003 (processing), and SCR-004 (transcript).

import SwiftUI

struct PreFlightContent: View {
    @StateObject private var vm: PreFlightViewModel
    let onRecord: () -> Void

    init(env: AppEnvironment, onRecord: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: PreFlightViewModel(env: env))
        self.onRecord = onRecord
    }

    var body: some View {
        ZStack {
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
                    RecordButton(action: onRecord)
                        .padding(.top, 8)
                    lastRecordingFootnote
                }
                .frame(maxWidth: DesignSpacing.Spacious.contentMaxWidth)
                .padding(48)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignColors.bgPrimary)
        .task { await vm.load() }
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle().fill(DesignColors.Status.success).frame(width: 6, height: 6)
            Text("Ready · all processing stays on this Mac")
                .font(DesignFonts.mono(11))
                .foregroundStyle(DesignColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(DesignColors.bgSecondary)
        .overlay(Capsule().stroke(DesignColors.borderDefault, lineWidth: 0.5))
        .clipShape(Capsule())
    }

    private var sourceToggles: some View {
        HStack(spacing: 12) {
            SourceToggle(systemIcon: "mic.fill", label: "Microphone",
                         sub: "MacBook Pro Microphone",
                         isOn: Binding(get: { vm.micEnabled }, set: { vm.micEnabled = $0 }))
            SourceToggle(systemIcon: "speaker.wave.2.fill", label: "System audio",
                         sub: "ScreenCaptureKit · all apps",
                         isOn: Binding(get: { vm.systemAudioEnabled }, set: { vm.systemAudioEnabled = $0 }))
        }
    }

    private var lastRecordingFootnote: some View {
        VStack(spacing: 16) {
            Rectangle().fill(DesignColors.borderDefault).frame(height: 0.5)
            HStack(spacing: 6) {
                Text("Last:").foregroundStyle(DesignColors.textSecondary)
                Text("Q3 Planning · Eng + Design").foregroundStyle(DesignColors.textPrimary)
                Text("· 32 min ago").foregroundStyle(DesignColors.textMuted)
            }
            .font(DesignFonts.ui(11.5))
        }
    }
}

#Preview {
    PreFlightContent(env: .preview(), onRecord: {})
        .frame(width: 860, height: 700)
}
