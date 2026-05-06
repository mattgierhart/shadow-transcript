// @implements API-001, INT-202, TECH-004, RISK-004
import AVFoundation
import Foundation
#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

public protocol SystemAudioSource: Sendable {
    /// Begins delivering system-audio PCM buffers synchronously to `consume`.
    /// Throws `screenRecordingPermissionDenied` if TCC denies access.
    func start(
        configuration: AudioCaptureConfiguration,
        consume: @escaping AudioBufferConsumer
    ) async throws

    func stop() async
}

#if canImport(ScreenCaptureKit)
/// Real implementation backed by `ScreenCaptureKit` (TECH-004 / INT-202).
public final class ScreenCaptureKitSystemAudioSource: NSObject, SystemAudioSource, @unchecked Sendable {
    private var stream: SCStream?
    private let outputQueue = DispatchQueue(label: "ai.gearheart.TranscriptShadow.SystemAudio")
    private let lock = NSLock()
    private var consumer: AudioBufferConsumer?

    public override init() { super.init() }

    public func start(
        configuration: AudioCaptureConfiguration,
        consume: @escaping AudioBufferConsumer
    ) async throws {
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        } catch {
            throw AudioCaptureError.screenRecordingPermissionDenied
        }

        guard let display = content.displays.first else {
            throw AudioCaptureError.unsupportedSystemConfiguration(reason: "No displays available for ScreenCaptureKit.")
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])

        let scConfiguration = SCStreamConfiguration()
        scConfiguration.capturesAudio = true
        scConfiguration.excludesCurrentProcessAudio = false
        scConfiguration.sampleRate = Int(configuration.sampleRate)
        scConfiguration.channelCount = configuration.channelCount
        scConfiguration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        scConfiguration.width = 2
        scConfiguration.height = 2

        let stream = SCStream(filter: filter, configuration: scConfiguration, delegate: nil)
        do {
            try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: outputQueue)
        } catch {
            throw AudioCaptureError.systemAudioCaptureFailedToStart(reason: error.localizedDescription)
        }

        lock.withLock {
            consumer = consume
            self.stream = stream
        }

        do {
            try await stream.startCapture()
        } catch {
            await stop()
            throw AudioCaptureError.systemAudioCaptureFailedToStart(reason: error.localizedDescription)
        }
    }

    public func stop() async {
        let stream = lock.withLock { () -> SCStream? in
            let snapshot = self.stream
            self.stream = nil
            consumer = nil
            return snapshot
        }
        if let stream {
            try? await stream.stopCapture()
        }
    }
}

extension ScreenCaptureKitSystemAudioSource: SCStreamOutput {
    public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio,
              CMSampleBufferDataIsReady(sampleBuffer),
              let buffer = sampleBuffer.toPCMBuffer()
        else { return }
        let consumer = lock.withLock { self.consumer }
        consumer?(AudioBufferEnvelope(buffer))
    }
}

private extension CMSampleBuffer {
    func toPCMBuffer() -> AVAudioPCMBuffer? {
        guard let formatDescription = CMSampleBufferGetFormatDescription(self),
              let asbdPointer = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
        else { return nil }

        var basic = asbdPointer.pointee
        guard let avFormat = AVAudioFormat(streamDescription: &basic) else { return nil }

        let sampleCount = CMSampleBufferGetNumSamples(self)
        guard sampleCount > 0 else { return nil }

        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: avFormat, frameCapacity: AVAudioFrameCount(sampleCount)) else { return nil }
        pcmBuffer.frameLength = AVAudioFrameCount(sampleCount)

        guard let blockBuffer = CMSampleBufferGetDataBuffer(self),
              let audioBufferPointer = pcmBuffer.audioBufferList.pointee.mBuffers.mData
        else { return nil }

        var lengthAtOffset = 0
        var totalLength = 0
        var dataPointer: UnsafeMutablePointer<Int8>? = nil
        let status = CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: &lengthAtOffset, totalLengthOut: &totalLength, dataPointerOut: &dataPointer)
        guard status == kCMBlockBufferNoErr, let dataPointer else { return nil }

        let availableBytes = Int(pcmBuffer.audioBufferList.pointee.mBuffers.mDataByteSize)
        let copyCount = min(totalLength, availableBytes)
        memcpy(audioBufferPointer, dataPointer, copyCount)
        return pcmBuffer
    }
}
#endif
