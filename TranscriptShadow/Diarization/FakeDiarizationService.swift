// @implements API-102, INT-102
import Foundation

/// In-memory stand-in for `DiarizationService` that returns a pre-baked
/// `DiarizationResult` (or throws a pre-baked error). Used by tests in
/// EPIC-04b, EPIC-05 (formatter), and EPIC-07 (UI) so the upstream code
/// can be exercised without spawning a real subprocess or shipping the
/// PyInstaller bundle.
///
/// Mirrors the test-double pattern in `Audio/FakeAudioCaptureService` and
/// `Transcription/FakeTranscriptionService`.
public final class FakeDiarizationService: DiarizationService, @unchecked Sendable {
    private let lock = NSLock()
    private var nextOutcome: Outcome
    private var calls: [URL] = []

    public enum Outcome: Sendable {
        case success(DiarizationResult)
        case failure(DiarizationError)
    }

    public init(outcome: Outcome = .success(.empty)) {
        self.nextOutcome = outcome
    }

    /// Replace the next call's outcome. Subsequent calls keep returning
    /// the same outcome until set again — matches `FakeTranscriptionService`.
    public func setOutcome(_ outcome: Outcome) {
        lock.withLock { self.nextOutcome = outcome }
    }

    /// Record of every audio URL passed to `diarize(...)`, in call order.
    public var receivedAudioURLs: [URL] {
        lock.withLock { self.calls }
    }

    public func diarize(
        audioURL: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> DiarizationResult {
        lock.withLock { self.calls.append(audioURL) }

        progress(0.0)
        try Task.checkCancellation()

        let outcome = lock.withLock { self.nextOutcome }
        switch outcome {
        case .success(let result):
            progress(1.0)
            return result
        case .failure(let error):
            throw error
        }
    }
}

public extension DiarizationResult {
    /// Empty result — useful default for `FakeDiarizationService`.
    static var empty: DiarizationResult {
        DiarizationResult(
            version: "1.0",
            audio: AudioInfo(path: "", durationSeconds: 0),
            model: ModelInfo(name: "fake", revision: "fake"),
            speakers: [],
            segments: [],
            overlappingSegments: [],
            elapsedSeconds: 0,
            warnings: []
        )
    }
}
