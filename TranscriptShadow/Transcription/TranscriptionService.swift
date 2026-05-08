// @implements API-101, FEA-002, BR-101, BR-202
import Foundation

/// Public transcription surface (API-101). Consumers hand a WAV URL produced
/// by `AudioCaptureService.stopCapture()` (or any readable WAV) and receive
/// segmented + word-timestamped text.
public protocol TranscriptionService: Sendable {
    /// Loads the requested model into memory, downloading it on first use.
    /// Idempotent — repeated calls with the same model are no-ops once
    /// loaded. Calling with a different model unloads the previous one.
    func prepare(model: WhisperModel) async throws

    /// Transcribes the audio at `audioURL`. The progress closure receives
    /// monotonic fractional values in `[0.0, 1.0]` and is guaranteed to fire
    /// at least once with `0.0` at the start and `1.0` on success.
    ///
    /// English-only per BR-202. Audio is processed entirely on-device per
    /// BR-101 — no network calls beyond the one-time model download.
    func transcribe(
        audioURL: URL,
        model: WhisperModel,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> Transcript

    /// The currently loaded model, if any. Mostly useful in tests to assert
    /// the cache invariant for TEST-104.
    var loadedModel: WhisperModel? { get async }
}

public extension TranscriptionService {
    func transcribe(
        audioURL: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> Transcript {
        try await transcribe(audioURL: audioURL, model: .default, progress: progress)
    }

    func transcribe(audioURL: URL) async throws -> Transcript {
        try await transcribe(audioURL: audioURL, model: .default, progress: { _ in })
    }
}
