// @implements SCR-002 (Recording HUD content — shared by DES-105 + DES-106)
// @see SoT/SoT.DESIGN_COMPONENTS.md DES-105, DES-106
// @see design/visual-prototype/project/src/scr002.jsx
//
// Per BR-501, the HUD exposes exactly one action: Stop. Both the Notch panel
// (DES-105) and the Menu Bar popover (DES-106) host the same visual: red dot
// (1Hz oscillation), "Recording" label, Stop button. Visual parity is mandatory.

import SwiftUI

struct RecordingHUDContent: View {
    /// `.compact` is the notch-panel layout (horizontal, 36pt tall).
    /// `.popover` is the menu-bar popover layout (vertical, 80pt tall, full-width Stop).
    enum Layout { case compact, popover }

    let layout: Layout
    let onStop: () -> Void

    @State private var pulse = false

    var body: some View {
        switch layout {
        case .compact: compactLayout
        case .popover: popoverLayout
        }
    }

    // MARK: - Compact (notch panel)

    private var compactLayout: some View {
        HStack(spacing: 10) {
            redDot
            Text("Recording")
                .font(DesignFonts.ui(12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.92))
            Spacer(minLength: 0)
            stopButtonCompact
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .clipShape(notchShape)
        .shadow(color: .black.opacity(0.55), radius: 16, y: 12)
        .onAppear { pulse = true }
    }

    private var notchShape: some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 18,
            bottomTrailingRadius: 18,
            topTrailingRadius: 0
        )
    }

    private var stopButtonCompact: some View {
        Button(action: onStop) {
            HStack(spacing: 6) {
                Rectangle().fill(Color.white).frame(width: 8, height: 8)
                Text("Stop")
                    .font(DesignFonts.ui(11.5, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(DesignColors.recordingRed)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Popover (menu bar)

    private var popoverLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                redDot
                Text("Recording")
                    .font(DesignFonts.ui(13, weight: .semibold))
                    .foregroundStyle(DesignColors.textPrimary)
                Spacer()
                Text("⌘⇧.")
                    .font(DesignFonts.mono(10.5))
                    .foregroundStyle(DesignColors.textMuted)
            }
            stopButtonPopover
        }
        .padding(12)
        .frame(width: 220, height: 80)
        .background(Color(hex: 0x1C1C1E).opacity(0.96))
        .onAppear { pulse = true }
    }

    private var stopButtonPopover: some View {
        Button(action: onStop) {
            HStack(spacing: 8) {
                Rectangle().fill(Color.white).frame(width: 10, height: 10)
                Text("Stop")
                    .font(DesignFonts.ui(13, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(DesignColors.recordingRed)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Liveness signal

    private var redDot: some View {
        Circle()
            .fill(DesignColors.recordingRed)
            .frame(width: 9, height: 9)
            .shadow(color: DesignColors.recordingRed, radius: 6)
            .opacity(pulse ? 1.0 : 0.55)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: pulse)
    }
}

#Preview("Compact (notch)") {
    RecordingHUDContent(layout: .compact, onStop: {})
        .frame(width: 320, height: 38)
        .padding(40)
        .background(Color(hex: 0x202022))
}

#Preview("Popover (menu bar)") {
    RecordingHUDContent(layout: .popover, onStop: {})
        .padding(40)
        .background(Color(hex: 0x202022))
}
