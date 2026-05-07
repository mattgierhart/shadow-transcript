// @implements API-002
import AVFoundation
import Foundation

/// Combines microphone and system-audio PCM buffers into a single mono WAV
/// file. Sources are summed sample-by-sample with a 0.5 attenuation per source
/// so the mix stays inside the [-1, 1] range without hard clipping.
public enum AudioMixer {

    /// Mixes equal-length buffers (or the shorter of the two) into `outputURL`.
    /// Used by tests (TEST-003); production capture uses
    /// `MixingFileWriter` which streams arbitrary-length buffers.
    public static func mix(
        microphoneBuffer micBuffer: AVAudioPCMBuffer,
        systemBuffer: AVAudioPCMBuffer,
        sampleRate: Double = 48_000,
        to outputURL: URL
    ) throws {
        let format = try outputFormat(sampleRate: sampleRate)
        let frameCount = min(micBuffer.frameLength, systemBuffer.frameLength)
        guard frameCount > 0,
              let mixed = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioCaptureError.audioFileWriteFailed(reason: "Unable to allocate mix buffer.")
        }
        mixed.frameLength = frameCount

        guard let micChannel = AudioMixer.monoFloatChannel(for: micBuffer),
              let systemChannel = AudioMixer.monoFloatChannel(for: systemBuffer),
              let outChannel = mixed.floatChannelData?[0] else {
            throw AudioCaptureError.audioFileWriteFailed(reason: "Source buffers must contain float PCM samples.")
        }

        for frame in 0..<Int(frameCount) {
            outChannel[frame] = (micChannel[frame] + systemChannel[frame]) * 0.5
        }

        let writer = try AudioFileWriter(url: outputURL, format: format)
        try writer.write(buffer: mixed)
        try writer.finish()
    }

    /// Mixes two on-disk WAV files (one mic, one system) into a single mono
    /// WAV at `outputURL`. Used by `DefaultAudioCaptureService` when both
    /// sources are active so each source writes to its own per-session file
    /// in real time and the streams are merged at stop.
    public static func mixFiles(
        microphoneFile micURL: URL,
        systemFile sysURL: URL,
        to outputURL: URL
    ) throws {
        let micFile = try AVAudioFile(forReading: micURL)
        let sysFile = try AVAudioFile(forReading: sysURL)

        let sampleRate = max(micFile.processingFormat.sampleRate, sysFile.processingFormat.sampleRate)
        let format = try outputFormat(sampleRate: sampleRate)

        let totalFrames = max(micFile.length, sysFile.length)
        guard totalFrames > 0 else {
            throw AudioCaptureError.audioFileWriteFailed(reason: "Both source files are empty.")
        }

        let writer = try AudioFileWriter(url: outputURL, format: format)
        let chunkFrames: AVAudioFrameCount = 4_096
        var remainingMic = micFile.length
        var remainingSys = sysFile.length

        while remainingMic > 0 || remainingSys > 0 {
            let micChunk: AVAudioPCMBuffer? = try readChunk(
                from: micFile,
                remaining: &remainingMic,
                chunkFrames: chunkFrames,
                targetFormat: format
            )
            let sysChunk: AVAudioPCMBuffer? = try readChunk(
                from: sysFile,
                remaining: &remainingSys,
                chunkFrames: chunkFrames,
                targetFormat: format
            )
            let frameCount = max(micChunk?.frameLength ?? 0, sysChunk?.frameLength ?? 0)
            guard frameCount > 0 else { break }

            guard let mixed = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                throw AudioCaptureError.audioFileWriteFailed(reason: "Could not allocate mix chunk.")
            }
            mixed.frameLength = frameCount
            guard let outChannel = mixed.floatChannelData?[0] else {
                throw AudioCaptureError.audioFileWriteFailed(reason: "Mix chunk has no float channel.")
            }
            for frame in 0..<Int(frameCount) {
                let micSample = (frame < Int(micChunk?.frameLength ?? 0)) ? (micChunk?.floatChannelData?[0][frame] ?? 0) : 0
                let sysSample = (frame < Int(sysChunk?.frameLength ?? 0)) ? (sysChunk?.floatChannelData?[0][frame] ?? 0) : 0
                outChannel[frame] = (micSample + sysSample) * 0.5
            }
            try writer.write(buffer: mixed)
        }
        try writer.finish()
    }

    private static func readChunk(
        from file: AVAudioFile,
        remaining: inout AVAudioFramePosition,
        chunkFrames: AVAudioFrameCount,
        targetFormat: AVAudioFormat
    ) throws -> AVAudioPCMBuffer? {
        guard remaining > 0 else { return nil }
        let frameCount = AVAudioFrameCount(min(AVAudioFramePosition(chunkFrames), remaining))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount) else {
            return nil
        }
        try file.read(into: buffer, frameCount: frameCount)
        remaining -= AVAudioFramePosition(buffer.frameLength)
        if buffer.format.isEquivalent(to: targetFormat) {
            return buffer
        }
        return AudioBufferConverter.convert(buffer, to: targetFormat)
    }

    static func outputFormat(sampleRate: Double) throws -> AVAudioFormat {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false) else {
            throw AudioCaptureError.unsupportedSystemConfiguration(reason: "Could not allocate AVAudioFormat at \(sampleRate) Hz mono float.")
        }
        return format
    }

    /// Returns a pointer to a mono float channel. If the buffer is multi-channel
    /// it is downmixed (averaged) into a freshly allocated array so the caller
    /// can read it linearly. Returns nil for non-float-PCM buffers.
    static func monoFloatChannel(for buffer: AVAudioPCMBuffer) -> UnsafeMutablePointer<Float>? {
        guard let channelData = buffer.floatChannelData else { return nil }
        let channels = Int(buffer.format.channelCount)
        if channels == 1 { return channelData[0] }

        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return channelData[0] }

        // Downmix into the first channel in place — buffer is consumed once.
        let target = channelData[0]
        let inverseChannels = 1.0 / Float(channels)
        for frame in 0..<frameCount {
            var sum: Float = 0
            for channel in 0..<channels {
                sum += channelData[channel][frame]
            }
            target[frame] = sum * inverseChannels
        }
        return target
    }
}
