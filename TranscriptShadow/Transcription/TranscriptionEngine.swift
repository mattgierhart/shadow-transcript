// @implements API-101
import Foundation

/// Internal seam between `DefaultTranscriptionService` and the actual
/// inference engine. Lets unit tests substitute a `FakeTranscriptionEngine`
/// without pulling in WhisperKit, model downloads, or hardware. The shape of
/// the engine output mirrors what we hand back to callers, minus duration
/// (which the service measures from the input WAV) and minus model identity
/// (the service tracks that).
protocol TranscriptionEngine: Sendable {
    /// Loads the model into memory. Idempotent for the same model.
    func load(model: WhisperModel, store: TranscriptionModelStore) async throws

    /// Returns the model the engine currently has loaded, if any.
    var loaded: WhisperModel? { get async }

    /// Runs transcription. Implementations should fire `progress` at least
    /// twice (0.0 at start, 1.0 at the end) and otherwise as often as the
    /// underlying engine reports useful intermediate state.
    func transcribe(
        audioURL: URL,
        language: String,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> EngineTranscription
}

/// Engine-level transcription payload. `language` is the detected (or
/// requested) language; `segments` arrive in the same order the engine
/// produced them.
struct EngineTranscription: Sendable, Equatable {
    let language: String
    let segments: [TranscriptSegment]

    init(language: String, segments: [TranscriptSegment]) {
        self.language = language
        self.segments = segments
    }
}
