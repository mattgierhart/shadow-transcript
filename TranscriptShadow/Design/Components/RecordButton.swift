// @implements DES-001 (Record Button — start only; Stop lives on HUD per BR-501)
// @see SoT/SoT.DESIGN_COMPONENTS.md DES-001
// @see design/visual-prototype/project/src/scr001.jsx :: RecordButton

import SwiftUI

struct RecordButton: View {
    let isEnabled: Bool
    let action: () -> Void

    init(isEnabled: Bool = true, action: @escaping () -> Void) {
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        VStack(spacing: 14) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(isEnabled ? DesignColors.recordingRed : Color(hex: 0x3A3A3C))
                        .frame(width: DesignSpacing.Component.recordButtonSize,
                               height: DesignSpacing.Component.recordButtonSize)
                        .shadow(color: DesignColors.recordingRed.opacity(0.25), radius: 12, y: 4)
                        .overlay(
                            Circle()
                                .stroke(DesignColors.recordingRed.opacity(0.10), lineWidth: 6)
                        )

                    // Inner white dot (the "record" affordance).
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .opacity(0.95)
                }
                .opacity(isEnabled ? 1.0 : 0.3)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
            .keyboardShortcut(.space, modifiers: [])

            VStack(spacing: 3) {
                Text("Start recording")
                    .font(DesignFonts.ui(13, weight: .medium))
                    .foregroundStyle(DesignColors.textPrimary)
                Text("Space")
                    .font(DesignFonts.mono(11))
                    .foregroundStyle(DesignColors.textMuted)
            }
        }
    }
}

#Preview {
    RecordButton {}
        .padding(40)
        .background(DesignColors.bgPrimary)
}
