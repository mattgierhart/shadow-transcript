// @implements ARC-001, ARC-003
// Public contract for the EPIC-08 pipeline orchestrator. Composes the
// six services from AppEnvironment into a single sequential pipeline
// (capture → transcribe → diarize → format → store → optional export)
// and emits a monotonic aggregate progress fraction across stages.
//
// Progress weighting (must stay aligned with DefaultPipelineOrchestrator):
//   transcribe   → 0.0 → 0.6
//   diarize      → 0.6 → 0.9
//   format       → 0.9 → 0.92
//   save         → 0.92 → 0.97
//   export       → 0.97 → 1.0
// Sum = 1.0, monotonic, no stage rewinds.

import Foundation

public enum PipelineStageIdentifier: String, Sendable, Equatable, CaseIterable {
    case transcribe
    case diarize
    case format
    case save
    case export
}

public struct PipelineProgress: Sendable, Equatable {
    public let stage: PipelineStageIdentifier
    public let stageFraction: Double
    public let aggregateFraction: Double

    public init(stage: PipelineStageIdentifier, stageFraction: Double, aggregateFraction: Double) {
        self.stage = stage
        self.stageFraction = stageFraction
        self.aggregateFraction = aggregateFraction
    }
}

public protocol PipelineOrchestrator: Sendable {
    /// Runs the full pipeline on the given audio file. Returns the
    /// stored transcript's UUID on success. Throws `OrchestrationError`
    /// for typed failures; throws `OrchestrationError.cancelled` if
    /// `Task.cancel()` lands on the calling task.
    ///
    /// The temp audio at `audioURL` is deleted on every exit path
    /// (success / cancel / error) via the injected `TempAudioCleanup`.
    func process(
        audioURL: URL,
        progress: @escaping @Sendable (PipelineProgress) -> Void
    ) async throws -> UUID
}

public extension PipelineOrchestrator {
    /// Convenience for callers that don't care about progress.
    func process(audioURL: URL) async throws -> UUID {
        try await process(audioURL: audioURL, progress: { _ in })
    }
}
