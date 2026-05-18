// @implements DES-102 (Progress Pipeline)
// @see SoT/SoT.DESIGN_COMPONENTS.md DES-102
// @see design/visual-prototype/project/src/scr003.jsx :: PipelineStage

import SwiftUI

struct PipelineStage: Identifiable, Equatable {
    enum Status { case waiting, active, done, error }

    let id: String
    let label: String
    let sub: String
    let percent: Int
    let status: Status
}

struct ProgressPipeline: View {
    let stages: [PipelineStage]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(stages) { stage in
                StageRow(stage: stage)
            }
        }
    }

    private struct StageRow: View {
        let stage: PipelineStage
        @State private var pulse = false

        var body: some View {
            HStack(spacing: 14) {
                StatusDot(status: stage.status, pulse: $pulse)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(stage.label)
                            .font(DesignFonts.ui(13, weight: .medium))
                            .foregroundStyle(DesignColors.textPrimary)
                        Text(stage.sub)
                            .font(DesignFonts.mono(11))
                            .foregroundStyle(DesignColors.textSecondary)
                    }
                    progressBar
                }
                Text("\(stage.percent)%")
                    .font(DesignFonts.mono(11))
                    .foregroundStyle(percentColor)
                    .frame(minWidth: 44, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(rowBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(rowBorder, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onAppear { if stage.status == .active { pulse = true } }
        }

        private var rowBackground: Color {
            stage.status == .active ? DesignColors.accentPrimary.opacity(0.06) : .clear
        }
        private var rowBorder: Color {
            stage.status == .active ? DesignColors.accentPrimary.opacity(0.30) : DesignColors.borderDefault
        }
        private var percentColor: Color {
            switch stage.status {
            case .active: return DesignColors.accentPrimary
            case .done: return DesignColors.Status.success
            case .error: return DesignColors.Status.error
            case .waiting: return DesignColors.textMuted
            }
        }

        @ViewBuilder
        private var progressBar: some View {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999)
                        .fill(DesignColors.bgTertiary)
                    RoundedRectangle(cornerRadius: 999)
                        .fill(stage.status == .done ? DesignColors.Status.success : DesignColors.accentPrimary)
                        .frame(width: geo.size.width * CGFloat(stage.percent) / 100.0)
                        .animation(.easeOut(duration: 0.4), value: stage.percent)
                }
            }
            .frame(height: 3)
        }
    }

    private struct StatusDot: View {
        let status: PipelineStage.Status
        @Binding var pulse: Bool

        var body: some View {
            ZStack {
                Circle()
                    .fill(bgFill)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle().stroke(borderColor, lineWidth: 0.5)
                    )
                inner
            }
        }

        @ViewBuilder
        private var inner: some View {
            switch status {
            case .done:
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DesignColors.Status.success)
            case .active:
                Circle()
                    .fill(DesignColors.accentPrimary)
                    .frame(width: 10, height: 10)
                    .shadow(color: DesignColors.accentPrimary, radius: 6)
                    .opacity(pulse ? 1.0 : 0.55)
                    .animation(.easeInOut(duration: 1.4).repeatForever(), value: pulse)
            case .error:
                Image(systemName: "exclamationmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DesignColors.Status.error)
            case .waiting:
                Circle().fill(DesignColors.textMuted).frame(width: 8, height: 8)
            }
        }

        private var bgFill: Color {
            switch status {
            case .active: return DesignColors.accentPrimary.opacity(0.12)
            case .done: return DesignColors.Status.success.opacity(0.12)
            default: return DesignColors.bgTertiary
            }
        }
        private var borderColor: Color {
            switch status {
            case .active: return DesignColors.accentPrimary.opacity(0.35)
            case .done: return DesignColors.Status.success.opacity(0.35)
            default: return DesignColors.borderDefault
            }
        }
    }
}

#Preview {
    ProgressPipeline(stages: [
        PipelineStage(id: "t", label: "Transcribing", sub: "WhisperKit · small.en", percent: 100, status: .done),
        PipelineStage(id: "d", label: "Identifying speakers", sub: "pyannote · sidecar", percent: 62, status: .active),
        PipelineStage(id: "f", label: "Formatting transcript", sub: "merge · markdown", percent: 0, status: .waiting),
    ])
    .frame(width: 500)
    .padding(40)
    .background(DesignColors.bgPrimary)
}
