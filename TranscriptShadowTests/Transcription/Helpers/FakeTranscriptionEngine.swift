import Foundation
@testable import TranscriptShadow

final class FakeTranscriptionEngine: TranscriptionEngine, @unchecked Sendable {
    private let lock = NSLock()
    private var _loaded: WhisperModel?
    private(set) var loadCallCount = 0
    private(set) var transcribeCallCount = 0
    /// Recorded order in which engine operations entered. Used to verify the
    /// service's serialization invariant against concurrent calls.
    private(set) var operationLog: [String] = []
    var transcribeDelayNanoseconds: UInt64 = 0

    var loadError: Error?
    var transcribeError: Error?
    /// Sequence of segments to return on the next `transcribe` call.
    var segmentsToReturn: [TranscriptSegment] = []
    var languageToReturn: String = "en"
    /// Progress fractions to emit during `transcribe`. Values are forwarded
    /// in order; the engine still emits 0.0 at start and 1.0 at end on top.
    var progressFractionsToEmit: [Double] = [0.25, 0.5, 0.75]

    var loaded: WhisperModel? {
        get async { lock.withLock { _loaded } }
    }

    func load(model: WhisperModel, store: TranscriptionModelStore) async throws {
        if let loadError { throw loadError }
        lock.withLock {
            _loaded = model
            loadCallCount += 1
        }
    }

    func transcribe(
        audioURL: URL,
        language: String,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> EngineTranscription {
        lock.withLock {
            transcribeCallCount += 1
            operationLog.append("transcribe-start:\(audioURL.lastPathComponent)")
        }
        if let transcribeError {
            lock.withLock { operationLog.append("transcribe-error:\(audioURL.lastPathComponent)") }
            throw transcribeError
        }
        if transcribeDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: transcribeDelayNanoseconds)
        }
        try Task.checkCancellation()
        progress(0)
        for fraction in progressFractionsToEmit {
            progress(fraction)
        }
        progress(1.0)
        lock.withLock { operationLog.append("transcribe-end:\(audioURL.lastPathComponent)") }
        return EngineTranscription(language: languageToReturn, segments: segmentsToReturn)
    }
}
