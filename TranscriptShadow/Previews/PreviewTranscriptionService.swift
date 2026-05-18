// @implements API-101
// In-memory `TranscriptionService` used for SwiftUI previews + view-model
// unit tests. Returns a single-segment `Transcript` without invoking
// WhisperKit or downloading a model.

import Foundation

public final class PreviewTranscriptionService: TranscriptionService, @unchecked Sendable {
    private let lock = NSLock()
    private var _loadedModel: WhisperModel?
    public private(set) var prepareCallCount = 0
    public private(set) var transcribeCallCount = 0

    /// Result returned from the next `transcribe(...)` call. Defaults to a
    /// trivial one-segment transcript so previews don't crash.
    public var nextTranscript: Transcript = Transcript(
        segments: [
            TranscriptSegment(
                text: "Preview transcript text.",
                start: 0,
                end: 5,
                words: [
                    WordTimestamp(word: "Preview", start: 0, end: 1),
                    WordTimestamp(word: "transcript", start: 1, end: 3),
                    WordTimestamp(word: "text.", start: 3, end: 5)
                ]
            )
        ],
        language: "en",
        duration: 5,
        model: .baseEN
    )

    public var prepareError: Error?
    public var transcribeError: Error?
    /// Sleep this many nanoseconds inside `transcribe` before returning,
    /// so tests can race the call against a cancel.
    public var transcribeDelayNanoseconds: UInt64 = 0

    public init() {}

    public func prepare(model: WhisperModel) async throws {
        if let prepareError { throw prepareError }
        lock.withLock {
            _loadedModel = model
            prepareCallCount += 1
        }
    }

    public func transcribe(
        audioURL: URL,
        model: WhisperModel,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> Transcript {
        if let transcribeError { throw transcribeError }
        lock.withLock {
            transcribeCallCount += 1
            _loadedModel = model
        }
        progress(0.0)
        if transcribeDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: transcribeDelayNanoseconds)
        }
        try Task.checkCancellation()
        progress(0.5)
        progress(1.0)
        return nextTranscript
    }

    public var loadedModel: WhisperModel? {
        get async { lock.withLock { _loadedModel } }
    }
}
