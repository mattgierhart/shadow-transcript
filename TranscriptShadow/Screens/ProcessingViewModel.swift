// @implements SCR-003, UJ-001
// View-model for the SCR-003 processing view. Phase 1 holds the canned
// stages so the view renders identically. Phase 3 wires the real pipeline:
// transcription progress (0-60%), diarization (60-90%), format+save+export
// (90-100%); cancel propagates via `Task.cancel()` through every stage.

import Combine
import Foundation

@MainActor
final class ProcessingViewModel: ObservableObject {
    @Published var title: String = "Q3 Planning · Eng + Design"
    @Published var elapsed: String = "47:12 captured"
    @Published var estimatedRemaining: String = "est. 2 min 10 s remaining"
    @Published var stages: [PipelineStage] = ProcessingView.mockStages
    @Published var error: String?

    let env: AppEnvironment
    var onComplete: ((UUID) -> Void)?
    var onCancel: (() -> Void)?

    private var pipelineTask: Task<Void, Never>?

    init(env: AppEnvironment) {
        self.env = env
    }

    /// Phase 3 entry point. Today this is a no-op so the demo flow
    /// (Cmd+2) still shows the canned stages.
    func start(audioURL: URL) {
        // intentionally empty in Phase 1
    }

    func cancel() {
        pipelineTask?.cancel()
        pipelineTask = nil
        onCancel?()
    }
}
