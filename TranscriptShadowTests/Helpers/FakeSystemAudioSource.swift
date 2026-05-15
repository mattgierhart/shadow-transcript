import AVFoundation
import Foundation
@testable import TranscriptShadow

final class FakeSystemAudioSource: SystemAudioSource, @unchecked Sendable {
    private let lock = NSLock()
    private var consumer: AudioBufferConsumer?
    private(set) var startCount = 0
    private(set) var stopCount = 0
    var startError: Error?

    func start(configuration: AudioCaptureConfiguration, consume: @escaping AudioBufferConsumer) async throws {
        if let startError { throw startError }
        lock.withLock {
            consumer = consume
            startCount += 1
        }
    }

    func stop() async {
        lock.withLock {
            consumer = nil
            stopCount += 1
        }
    }

    func push(_ buffer: AVAudioPCMBuffer) {
        let consumer = lock.withLock { self.consumer }
        consumer?(AudioBufferEnvelope(buffer))
    }
}
