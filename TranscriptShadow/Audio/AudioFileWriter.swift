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
        // Refuse to silently overwrite an existing file. Callers (the orchestrator)
        // generate unique URLs via `AudioCaptureLocations.newRecordingURL`; if the
        // file already exists at this point something else owns it (RISK-006).
        if FileManager.default.fileExists(atPath: url.path) {
            throw AudioCaptureError.audioFileWriteFailed(
                reason: "Refusing to overwrite existing file at \(url.lastPathComponent)."
            )
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
        // Single critical section: validate, possibly convert, write, and bump
        // the frame counter atomically. Splitting these across multiple
        // `withLock` calls let `finish()` race in between and silently drop
        // audio while still incrementing `totalFrames`.
        try lock.withLock {
            guard !finished, let file else {
                throw AudioCaptureError.audioFileWriteFailed(reason: "Writer is not open.")
            }
            let target = file.processingFormat
            let toWrite: AVAudioPCMBuffer
            if buffer.format.isEquivalent(to: target) {
                toWrite = buffer
            } else if let converted = AudioBufferConverter.convert(buffer, to: target) {
                toWrite = converted
            } else {
                throw AudioCaptureError.audioFileWriteFailed(reason: "Could not convert buffer to writer format.")
            }
            do {
                try file.write(from: toWrite)
            } catch {
                throw AudioCaptureError.audioFileWriteFailed(reason: error.localizedDescription)
            }
            totalFrames += AVAudioFramePosition(toWrite.frameLength)
        }
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
