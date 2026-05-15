// @implements API-102, INT-102, FEA-003, BR-101
import Foundation

/// Public diarization surface (API-102, Swift consumer half).
///
/// Consumers hand a WAV URL produced by `AudioCaptureService.stopCapture()`
/// (or any readable WAV) and receive speaker segments. The implementation
/// spawns the EPIC-04a `diarize` binary as a subprocess and parses the
/// JSON envelope — see `PyannoteSidecarDiarizationService`.
///
/// Per BR-101 the audio never leaves the machine; the subprocess runs
/// entirely on-device. Network access is only required on the first run
/// to download the gated community-1 model from Hugging Face.
public protocol DiarizationService: Sendable {
    /// Diarizes the audio at `audioURL`.
    ///
    /// The progress closure receives fractional values in `[0.0, 1.0]`
    /// and is guaranteed to fire at least once with `0.0` at the start
    /// and `1.0` on success. Progress is forwarded from the sidecar's
    /// stdout `PROGRESS:` line stream (regex `^PROGRESS:(\d+(?:\.\d+)?)$`).
    ///
    /// Cancellation propagates to the subprocess via SIGTERM (graceful) +
    /// SIGKILL after a short grace period. A cancelled call throws
    /// `DiarizationError.cancelled` — never `.binaryFailed`.
    func diarize(
        audioURL: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> DiarizationResult
}

public extension DiarizationService {
    func diarize(audioURL: URL) async throws -> DiarizationResult {
        try await diarize(audioURL: audioURL, progress: { _ in })
    }
}
