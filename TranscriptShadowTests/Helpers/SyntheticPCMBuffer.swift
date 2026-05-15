import AVFoundation
@testable import TranscriptShadow

enum SyntheticPCMBuffer {
    static func make(
        sampleRate: Double = 48_000,
        channels: AVAudioChannelCount = 1,
        frameCount: Int = 4_800,
        amplitude: Float = 0.5
    ) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: false
        )!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        for channel in 0..<Int(channels) {
            let data = buffer.floatChannelData![channel]
            for i in 0..<frameCount {
                data[i] = amplitude
            }
        }
        return buffer
    }

    static func sine(
        sampleRate: Double = 48_000,
        frequency: Double = 440,
        frameCount: Int = 4_800,
        amplitude: Float = 0.5
    ) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        let data = buffer.floatChannelData![0]
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            data[i] = amplitude * Float(sin(2.0 * .pi * frequency * t))
        }
        return buffer
    }
}
