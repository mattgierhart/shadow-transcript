// @implements API-001
import AVFoundation

/// Sendable wrapper around `AVAudioPCMBuffer` so capture sources can hand
/// buffers to consumers that may live on different concurrency contexts. The
/// underlying buffer is logically owned by exactly one consumer at a time
/// (sources never retain after invoking the consumer), so the @unchecked
/// Sendable conformance is sound for our use.
public struct AudioBufferEnvelope: @unchecked Sendable {
    public let buffer: AVAudioPCMBuffer
    public init(_ buffer: AVAudioPCMBuffer) { self.buffer = buffer }
}

public typealias AudioBufferConsumer = @Sendable (AudioBufferEnvelope) -> Void
