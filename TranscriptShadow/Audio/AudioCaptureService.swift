// @implements API-001, FEA-001, BR-101, BR-402
import Foundation

public protocol AudioCaptureService: Sendable {
    /// Begins a new capture using the given configuration. Throws if a capture
    /// is already in progress or if a required permission is denied for a
    /// requested source. System-audio failures degrade to mic-only when the
    /// configuration permits microphone capture (TEST-005).
    func startCapture(configuration: AudioCaptureConfiguration) async throws

    /// Ends the active capture and returns the URL of the produced WAV file.
    /// Throws if no capture is active.
    @discardableResult
    func stopCapture() async throws -> URL

    /// Audio level stream in [0.0, 1.0]. Emits ≥5 values/sec while capturing
    /// and terminates when the active capture ends (TEST-002).
    func audioLevels() -> AsyncStream<Float>

    /// Milestone stream for duration warning / limit / fallback events.
    func milestones() -> AsyncStream<AudioCaptureMilestone>

    var isCapturing: Bool { get async }
    var elapsedTime: TimeInterval { get async }
}

public extension AudioCaptureService {
    func startCapture() async throws {
        try await startCapture(configuration: .default)
    }
}
