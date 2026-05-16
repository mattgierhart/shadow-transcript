// @see SoT/SoT.USER_JOURNEYS.md SCR-001 Content
// @see design/visual-prototype/project/src/scr001.jsx :: SourceToggle
//
// Source-toggle row for SCR-001 pre-flight (microphone + system audio).
// Not a top-level DES- component — composes DES-001/002 surface.

import SwiftUI

struct SourceToggle: View {
    let systemIcon: String
    let label: String
    let sub: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon tile
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isOn ? DesignColors.accentPrimary.opacity(0.10) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isOn ? DesignColors.accentPrimary.opacity(0.3) : DesignColors.borderDefault,
                                    lineWidth: 0.5)
                    )
                    .frame(width: 32, height: 32)

                Image(systemName: systemIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isOn ? DesignColors.accentPrimary : DesignColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignFonts.ui(12.5, weight: .medium))
                    .foregroundStyle(DesignColors.textPrimary)
                Text(sub)
                    .font(DesignFonts.mono(10.5))
                    .foregroundStyle(DesignColors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 8)

            // iOS-style toggle pill
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? DesignColors.accentPrimary : Color(hex: 0x3A3A3C))
                    .frame(width: 26, height: 16)
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .padding(.horizontal, 2)
            }
            .animation(.easeInOut(duration: 0.2), value: isOn)
            .onTapGesture { isOn.toggle() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(isOn ? DesignColors.accentPrimary.opacity(0.06) : DesignColors.bgTertiary)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isOn ? DesignColors.accentPrimary.opacity(0.35) : DesignColors.borderDefault,
                        lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    VStack(spacing: 12) {
        SourceToggle(systemIcon: "mic.fill",
                     label: "Microphone",
                     sub: "MacBook Pro Microphone",
                     isOn: .constant(true))
        SourceToggle(systemIcon: "speaker.wave.2.fill",
                     label: "System audio",
                     sub: "ScreenCaptureKit · all apps",
                     isOn: .constant(true))
    }
    .frame(width: 480)
    .padding(40)
    .background(DesignColors.bgPrimary)
}
