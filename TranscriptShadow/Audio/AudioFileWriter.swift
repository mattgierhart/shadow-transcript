// @implements API-001, API-002, RISK-006
import AVFoundation
import Foundation

/// A small wrapper around `AVAudioFile` that opens a WAV file at the given URL
/// for writing in 32-bit float mono PCM. Writes happen incrementally so that a
/// crash mid-recording leaves a still-valid file on disk (RISK-006).
public final class AudioFileWriter: @unchecked Sendable {
    private var file: AVAudioFile?
    public let url: URL
    public let format: AVAudioFormat
    private var finished = false
    private var totalFrames: AVAudioFramePosition = 0
    private let lock = NSLock()

    public init(url: URL, format: AVAudioFormat) throws {
        self.url = url
        self.format = format

        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }

        do {
            self.file = try AVAudioFile(
                forWriting: url,
                settings: format.settings,
                commonFormat: format.commonFormat,
                interleaved: format.isInterleaved
            )
        } catch {
            throw AudioCaptureError.audioFileWriteFailed(reason: error.localizedDescription)
        }
    }

    public func write(buffer: AVAudioPCMBuffer) throws {
        let toWrite: AVAudioPCMBuffer = try lock.withLock {
            guard !finished, let file else {
                throw AudioCaptureError.audioFileWriteFailed(reason: "Writer is not open.")
            }
            let target = file.processingFormat
            if buffer.format.isEquivalent(to: target) {
                return buffer
            }
            guard let converted = AudioBufferConverter.convert(buffer, to: target) else {
                throw AudioCaptureError.audioFileWriteFailed(reason: "Could not convert buffer to writer format.")
            }
            return converted
        }

        let frames = AVAudioFramePosition(toWrite.frameLength)
        do {
            try lock.withLock { try file?.write(from: toWrite) }
        } catch let error as AudioCaptureError {
            throw error
        } catch {
            throw AudioCaptureError.audioFileWriteFailed(reason: error.localizedDescription)
        }
        lock.withLock { totalFrames += frames }
    }

    public func finish() throws {
        lock.withLock {
            finished = true
            // Releasing the AVAudioFile flushes and finalizes the WAV header.
            file = nil
        }
    }

    public var totalFrameCount: AVAudioFramePosition {
        lock.withLock { totalFrames }
    }
}

extension AVAudioFormat {
    /// `==` on `AVAudioFormat` is strict and treats two structurally identical
    /// formats as different when channel layouts differ slightly. We compare
    /// only the dimensions that affect `AVAudioFile.write(from:)`.
    func isEquivalent(to other: AVAudioFormat) -> Bool {
        return commonFormat == other.commonFormat
            && sampleRate == other.sampleRate
            && channelCount == other.channelCount
            && isInterleaved == other.isInterleaved
    }
}
