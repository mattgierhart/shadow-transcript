// @implements SCR-003 (Processing View — restored main window after Stop)
// @see SoT/SoT.USER_JOURNEYS.md SCR-003
// @see design/visual-prototype/project/src/scr003.jsx :: ScreenSCR003

import SwiftUI

struct ProcessingView: View {
    @StateObject private var vm: ProcessingViewModel
    let audioURL: URL?
    let onCancel: () -> Void
    let onComplete: (UUID) -> Void

    init(
        env: AppEnvironment,
        audioURL: URL? = nil,
        onCancel: @escaping () -> Void,
        onComplete: @escaping (UUID) -> Void = { _ in }
    ) {
        _vm = StateObject(wrappedValue: ProcessingViewModel(env: env))
        self.audioURL = audioURL
        self.onCancel = onCancel
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [DesignColors.accentPrimary.opacity(0.06), .clear],
                center: .init(x: 0.5, y: 0.42),
                startRadius: 0,
                endRadius: 420
            )
            .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 32) {
                    heading
                    ProgressPipeline(stages: vm.stages)
                    footer
                }
                .frame(maxWidth: DesignSpacing.Spacious.contentMaxWidth)
                .padding(48)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignColors.bgPrimary)
        .task(id: audioURL) {
            guard let audioURL else { return }
            vm.onComplete = onComplete
            vm.onCancel = onCancel
            vm.start(audioURL: audioURL)
        }
    }

    private var heading: some View {
        VStack(spacing: 6) {
            Text("RECORDING STOPPED · PROCESSING LOCALLY")
                .font(DesignFonts.mono(11))
                .tracking(0.8)
                .foregroundStyle(DesignColors.textMuted)
                .padding(.bottom, 4)
            Text(vm.title)
                .font(DesignFonts.ui(22, weight: .semibold))
                .foregroundStyle(DesignColors.textPrimary)
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                Text(vm.elapsed)
                if !vm.estimatedRemaining.isEmpty {
                    Text("·")
                    Text(vm.estimatedRemaining)
                }
            }
            .font(DesignFonts.mono(12))
            .foregroundStyle(DesignColors.textSecondary)
            if let error = vm.error {
                Text(error)
                    .font(DesignFonts.mono(11))
                    .foregroundStyle(DesignColors.Status.error)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Rectangle().fill(DesignColors.borderDefault).frame(height: 0.5)
            HStack {
                HStack(spacing: 4) {
                    Text("●").foregroundStyle(DesignColors.Status.success)
                    Text("audio stays on this Mac · auto-deleted on completion")
                }
                .font(DesignFonts.mono(11))
                .foregroundStyle(DesignColors.textMuted)

                Spacer()

                Button(action: {
                    vm.cancel()
                    onCancel()
                }) {
                    Text("Cancel")
                        .font(DesignFonts.ui(11.5))
                        .foregroundStyle(DesignColors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(DesignColors.borderDefault, lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    static let mockStages: [PipelineStage] = [
        PipelineStage(id: "transcribe", label: "Transcribing",
                      sub: "WhisperKit · small.en", percent: 100, status: .done),
        PipelineStage(id: "diarize", label: "Identifying speakers",
                      sub: "pyannote · sidecar", percent: 62, status: .active),
        PipelineStage(id: "format", label: "Formatting transcript",
                      sub: "merge · markdown", percent: 0, status: .waiting),
    ]
}

#Preview {
    ProcessingView(env: .preview(), audioURL: nil, onCancel: {})
        .frame(width: 860, height: 700)
}
