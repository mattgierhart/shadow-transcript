// @implements SCR-003, UJ-001, ARC-001
// View-model for the SCR-003 processing view. Phase 4 refactor: this
// is now a thin wrapper around `AppEnvironment.pipeline` (the
// `PipelineOrchestrator` from EPIC-08). The VM translates aggregate
// progress into per-stage UI updates and handles cancellation.

import Combine
import Foundation

@MainActor
final class ProcessingViewModel: ObservableObject {
    // SCR-003 state. Release starts neutral; the demo placeholder copy below
    // is DEBUG-only (F-2) — only reachable via the Cmd+2 demo flow, and it's
    // overwritten the instant a real pipeline run starts (see runPipeline).
    #if DEBUG
    @Published var title: String = "Q3 Planning · Eng + Design"
    @Published var elapsed: String = "47:12 captured"
    @Published var stages: [PipelineStage] = ProcessingView.mockStages
    #else
    @Published var title: String = ""
    @Published var elapsed: String = ""
    @Published var stages: [PipelineStage] = []
    #endif
    @Published var estimatedRemaining: String = ""
    @Published var error: String?
    @Published var isRunning: Bool = false

    let env: AppEnvironment
    /// (transcriptID, exportWarning?). The warning is non-nil when auto-export
    /// failed but the transcript saved (F-1) — the caller surfaces it.
    var onComplete: ((UUID, String?) -> Void)?
    var onCancel: (() -> Void)?

    private var pipelineTask: Task<Void, Never>?

    init(env: AppEnvironment) {
        self.env = env
    }

    /// Called by SCR-003 in `.task(id: audioURL)`. The orchestrator
    /// runs the pipeline; we translate its `PipelineProgress` into the
    /// 3-stage UI shape.
    func start(audioURL: URL) {
        pipelineTask?.cancel()
        pipelineTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.runPipeline(audioURL: audioURL)
            self.pipelineTask = nil
        }
    }

    func cancel() {
        pipelineTask?.cancel()
        pipelineTask = nil
        onCancel?()
    }

    // MARK: - Pipeline

    private func runPipeline(audioURL: URL) async {
        isRunning = true
        defer { isRunning = false }
        error = nil

        title = "Recording · \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
        elapsed = "Processing locally"
        estimatedRemaining = ""

        let model = (try? await env.settings.read(.whisperModel)) ?? .baseEN
        stages = [
            PipelineStage(id: "transcribe", label: "Transcribing",
                          sub: "WhisperKit · \(model.rawValue)", percent: 0, status: .active),
            PipelineStage(id: "diarize",    label: "Identifying speakers",
                          sub: "pyannote · sidecar",             percent: 0, status: .waiting),
            PipelineStage(id: "format",     label: "Saving transcript",
                          sub: "merge · markdown · sqlite",      percent: 0, status: .waiting),
        ]

        do {
            let result = try await env.pipeline.process(audioURL: audioURL) { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.apply(progress: progress)
                }
            }
            onComplete?(result.id, result.exportWarning)
        } catch OrchestrationError.cancelled {
            error = "Cancelled"
            onCancel?()
        } catch {
            self.error = describe(error)
            markActiveStageError()
        }
    }

    /// Maps `PipelineProgress.stage` onto our 3-row UI. Transcribe + diarize
    /// each get their own row; format / save / export collapse into the
    /// third "Saving transcript" row so the user sees three discrete
    /// stages even though the orchestrator runs five.
    private func apply(progress: PipelineProgress) {
        switch progress.stage {
        case .transcribe:
            updateStage(id: "transcribe", percent: Int(progress.stageFraction * 100), status: progress.stageFraction >= 1 ? .done : .active)
        case .diarize:
            updateStage(id: "transcribe", percent: 100, status: .done)
            updateStage(id: "diarize", percent: Int(progress.stageFraction * 100), status: progress.stageFraction >= 1 ? .done : .active)
        case .format, .save, .export:
            updateStage(id: "transcribe", percent: 100, status: .done)
            updateStage(id: "diarize",    percent: 100, status: .done)
            // Aggregate map of stage 3 (format / save / export → 90→100):
            // turn that span into a 0..100 stage-row percent.
            let lower = 0.9
            let pct = Int(min(max((progress.aggregateFraction - lower) / (1 - lower), 0), 1) * 100)
            let status: PipelineStage.Status = progress.aggregateFraction >= 1 ? .done : .active
            updateStage(id: "format", percent: pct, status: status)
        }
    }

    private func updateStage(id: String, percent: Int, status: PipelineStage.Status) {
        if let idx = stages.firstIndex(where: { $0.id == id }) {
            stages[idx] = PipelineStage(
                id: stages[idx].id,
                label: stages[idx].label,
                sub: stages[idx].sub,
                percent: max(min(percent, 100), 0),
                status: status
            )
        }
    }

    private func markActiveStageError() {
        if let idx = stages.firstIndex(where: { $0.status == .active }) {
            stages[idx] = PipelineStage(
                id: stages[idx].id,
                label: stages[idx].label,
                sub: stages[idx].sub,
                percent: stages[idx].percent,
                status: .error
            )
        }
    }

    private func describe(_ error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "\(error)"
    }
}
