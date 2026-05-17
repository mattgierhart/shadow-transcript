// @implements DES-101 (Speaker Label)
// @see SoT/SoT.DESIGN_COMPONENTS.md DES-101
// @see design/visual-prototype/project/src/shared.jsx :: SpeakerPill

import SwiftUI

struct SpeakerLabel: View {
    let name: String
    let colorIndex: Int
    let time: String?
    let isActive: Bool
    let isEditing: Bool
    let size: Size

    enum Size {
        case sm
        case lg

        var padV: CGFloat { self == .lg ? 5 : 3 }
        var padH: CGFloat { self == .lg ? 12 : 10 }
        var fontSize: CGFloat { self == .lg ? 12.5 : 11.5 }
        var dotSize: CGFloat { 6 }
    }

    init(
        name: String,
        colorIndex: Int,
        time: String? = nil,
        isActive: Bool = false,
        isEditing: Bool = false,
        size: Size = .sm
    ) {
        self.name = name
        self.colorIndex = colorIndex
        self.time = time
        self.isActive = isActive
        self.isEditing = isEditing
        self.size = size
    }

    var color: Color { DesignColors.speakerColor(index: colorIndex) }

    var body: some View {
        if isEditing {
            editingPill
        } else {
            displayPill
        }
    }

    private var displayPill: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: size.dotSize, height: size.dotSize)
            Text(name)
                .font(DesignFonts.ui(size.fontSize, weight: .medium))
                .foregroundStyle(color)
            if let time {
                Text(time)
                    .font(DesignFonts.mono(size.fontSize - 1))
                    .foregroundStyle(DesignColors.textSecondary)
                    .padding(.leading, 4)
            }
        }
        .padding(.horizontal, size.padH)
        .padding(.vertical, size.padV)
        .background(color.opacity(0.10))
        .overlay(
            Capsule().stroke(isActive ? color.opacity(0.4) : .clear, lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    private var editingPill: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: size.dotSize, height: size.dotSize)
            Text(name)
                .font(DesignFonts.ui(size.fontSize, weight: .medium))
                .foregroundStyle(DesignColors.textPrimary)
            Rectangle()
                .fill(DesignColors.accentPrimary)
                .frame(width: 1, height: 12)
                .modifier(BlinkModifier())
        }
        .padding(.horizontal, size.padH)
        .padding(.vertical, size.padV)
        .background(DesignColors.accentPrimary.opacity(0.10))
        .overlay(
            Capsule().stroke(DesignColors.accentPrimary, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

private struct BlinkModifier: ViewModifier {
    @State private var visible = true
    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    Task { @MainActor in visible.toggle() }
                }
            }
    }
}

#Preview {
    HStack(spacing: 12) {
        SpeakerLabel(name: "Lena Ortiz", colorIndex: 0, time: "14:08", size: .lg)
        SpeakerLabel(name: "Speaker 5", colorIndex: 4)
        SpeakerLabel(name: "Priya Iyer", colorIndex: 2, isEditing: true, size: .lg)
    }
    .padding(40)
    .background(DesignColors.bgPrimary)
}
