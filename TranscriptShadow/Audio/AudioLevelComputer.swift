// @implements API-001
import AVFoundation
import Foundation

/// Computes a normalized RMS level [0.0, 1.0] from a PCM buffer for the
/// audio-level visualization stream (TEST-002). Pure function — safe to call
/// from any actor.
public enum AudioLevelComputer {
    public static func level(for buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        let channels = Int(buffer.format.channelCount)
        var sumSquares: Float = 0
        var sampleCount = 0

        for channel in 0..<channels {
            let samples = channelData[channel]
            for i in 0..<frameLength {
                let sample = samples[i]
                sumSquares += sample * sample
                sampleCount += 1
            }
        }

        guard sampleCount > 0 else { return 0 }
        let rms = sqrt(sumSquares / Float(sampleCount))
        // Clamp into [0, 1]. Float PCM is typically already bounded to [-1, 1],
        // but ScreenCaptureKit / engine outputs occasionally exceed that.
        return min(max(rms, 0), 1)
    }
}
