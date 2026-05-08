import AVFoundation
import Foundation
@testable import TranscriptShadow

/// Writes a short synthetic WAV to a temp URL so transcription tests have a
/// readable input. Returns the URL plus a tear-down closure callers should
/// register with `addTeardownBlock`.
enum FixtureWAV {
    static func make(seconds: Double = 1.0, sampleRate: Double = 48_000) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("epic03-fixture-\(UUID().uuidString).wav")
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!
        let file = try AVAudioFile(
            forWriting: url,
            settings: format.settings,
            commonFormat: format.commonFormat,
            interleaved: format.isInterleaved
        )
        let frameCount = AVAudioFrameCount(seconds * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let channel = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            channel[i] = Float(sin(2.0 * .pi * 440.0 * t)) * 0.3
        }
        try file.write(from: buffer)
        return url
    }
}
