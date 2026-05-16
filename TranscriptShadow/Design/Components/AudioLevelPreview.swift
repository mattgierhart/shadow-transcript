// @implements DES-002 (Audio Level Preview — pre-record SCR-001 only; BR-501 forbids during record)
// @see SoT/SoT.DESIGN_COMPONENTS.md DES-002
// @see design/visual-prototype/project/src/scr001.jsx :: PreRecordLevels

import SwiftUI

struct AudioLevelPreview: View {
    /// 56 normalized [0,1] bar heights. In production these come from
    /// `AudioCaptureService.audioLevels()`; for the pre-flight visual we
    /// shape them like a couple of speech blobs.
    let levels: [Double]
    let isActive: Bool

    init(levels: [Double]? = nil, isActive: Bool = true) {
        self.levels = levels ?? Self.previewLevels()
        self.isActive = isActive
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("INPUT LEVEL")
                    .font(DesignFonts.ui(11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(DesignColors.textSecondary)
                Spacer()
                Text("pre-flight · −18 dBFS")
                    .font(DesignFonts.mono(10.5))
                    .foregroundStyle(DesignColors.textMuted)
            }

            HStack(alignment: .center, spacing: 3) {
                ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                    Bar(level: level, isActive: isActive)
                }
            }
            .frame(height: 56)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(DesignColors.bgSecondary)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(DesignColors.borderDefault, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private struct Bar: View {
        let level: Double
        let isActive: Bool

        var body: some View {
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(
                        isActive
                            ? LinearGradient(
                                colors: [DesignColors.accentPrimary, DesignColors.accentPrimaryHover],
                                startPoint: .top,
                                endPoint: .bottom)
                            : LinearGradient(colors: [DesignColors.textMuted], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(height: max(3, geo.size.height * level))
                    .opacity(isActive ? (0.5 + level * 0.5) : 0.35)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
        }
    }

    /// Speech-blob envelope shape — visually identical to the JSX prototype.
    private static func previewLevels() -> [Double] {
        (0..<56).map { i in
            let t = Double(i) / 56.0
            let env = sin(t * .pi * 2.3) * 0.45 + sin(t * 11) * 0.18 + 0.45
            let noise = (sin(Double(i) * 37.7) + 1) / 2 * 0.4
            return max(0.08, min(1.0, env * 0.75 + noise * 0.35))
        }
    }
}

#Preview {
    AudioLevelPreview()
        .frame(width: 480)
        .padding(40)
        .background(DesignColors.bgPrimary)
}
