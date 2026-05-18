// @implements API-001
// In-memory `AudioCaptureService` used for SwiftUI previews + view-model
// unit tests. Doesn't touch hardware or filesystem; `startCapture` records
// the configuration and `stopCapture` returns a fixed dummy URL.

import Foundation

public final class PreviewAudioCaptureService: AudioCaptureService, @unchecked Sendable {
    private let lock = NSLock()
    private var capturing = false
    private var startedAt: Date?
    public private(set) var startCount = 0
    public private(set) var stopCount = 0
    public private(set) var lastConfiguration: AudioCaptureConfiguration?

    /// URL `stopCapture()` returns. Defaults to a deterministic temp path.
    public var stopReturnURL: URL = URL(fileURLWithPath: "/tmp/preview-recording.wav")
    public var startError: Error?
    public var stopError: Error?

    public init() {}

    public func startCapture(configuration: AudioCaptureConfiguration) async throws {
        if let startError { throw startError }
        lock.withLock {
            capturing = true
            startedAt = Date()
            startCount += 1
            lastConfiguration = configuration
        }
    }

    @discardableResult
    public func stopCapture() async throws -> URL {
        if let stopError { throw stopError }
        let url = stopReturnURL
        lock.withLock {
            capturing = false
            startedAt = nil
            stopCount += 1
        }
        return url
    }

    public func audioLevels() -> AsyncStream<Float> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    public func milestones() -> AsyncStream<AudioCaptureMilestone> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    public var isCapturing: Bool {
        get async { lock.withLock { capturing } }
    }

    public var elapsedTime: TimeInterval {
        get async {
            lock.withLock {
                guard let startedAt else { return 0 }
                return Date().timeIntervalSince(startedAt)
            }
        }
    }
}
