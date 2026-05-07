import AVFoundation
import Foundation
@testable import TranscriptShadow

/// Mic source that adds an artificial delay during `start` so reentrancy
/// tests can race a second `startCapture` against the first while the actor
/// is suspended at the first await point.
final class SlowFakeMicrophoneSource: MicrophoneSource, @unchecked Sendable {
    private let lock = NSLock()
    private var consumer: AudioBufferConsumer?
    let startDelay: TimeInterval

    init(startDelay: TimeInterval = 0.2) { self.startDelay = startDelay }

    func start(configuration: AudioCaptureConfiguration, consume: @escaping AudioBufferConsumer) async throws {
        try await Task.sleep(nanoseconds: UInt64(startDelay * 1_000_000_000))
        lock.withLock { consumer = consume }
    }

    func stop() async {
        lock.withLock { consumer = nil }
    }

    func push(_ buffer: AVAudioPCMBuffer) {
        let consumer = lock.withLock { self.consumer }
        consumer?(AudioBufferEnvelope(buffer))
    }
}
