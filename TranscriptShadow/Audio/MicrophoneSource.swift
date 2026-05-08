// @implements API-001, INT-201, TECH-003
import AVFoundation
import Foundation

public protocol MicrophoneSource: Sendable {
    /// Begins delivering microphone PCM buffers synchronously to `consume`.
    /// The closure is invoked on the source's internal audio thread; consumers
    /// must be quick (write to file, compute level) and never block.
    func start(
        configuration: AudioCaptureConfiguration,
        consume: @escaping AudioBufferConsumer
    ) async throws

    func stop() async
}

/// Real implementation backed by `AVAudioEngine` (TECH-003 / INT-201).
public final class AVAudioEngineMicrophoneSource: MicrophoneSource, @unchecked Sendable {
    private let engine = AVAudioEngine()
    private let lock = NSLock()
    private var consumer: AudioBufferConsumer?
    private var tapInstalled = false

    public init() {}

    public func start(
        configuration: AudioCaptureConfiguration,
        consume: @escaping AudioBufferConsumer
    ) async throws {
        try await ensureMicrophonePermission()

        lock.withLock { consumer = consume }

        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 4_096, format: inputFormat) { [weak self] buffer, _ in
            self?.deliver(buffer)
        }
        lock.withLock { tapInstalled = true }

        do {
            try engine.start()
        } catch {
            await stop()
            throw AudioCaptureError.audioEngineFailedToStart(reason: error.localizedDescription)
        }
    }

    public func stop() async {
        let shouldRemoveTap = lock.withLock { () -> Bool in
            consumer = nil
            let removing = tapInstalled
            tapInstalled = false
            return removing
        }
        if shouldRemoveTap {
            engine.inputNode.removeTap(onBus: 0)
        }
        if engine.isRunning {
            engine.stop()
        }
    }

    private func deliver(_ buffer: AVAudioPCMBuffer) {
        let consumer = lock.withLock { self.consumer }
        consumer?(AudioBufferEnvelope(buffer))
    }

    private func ensureMicrophonePermission() async throws {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            if !granted { throw AudioCaptureError.microphonePermissionDenied }
        case .denied, .restricted:
            throw AudioCaptureError.microphonePermissionDenied
        @unknown default:
            throw AudioCaptureError.microphonePermissionDenied
        }
    }
}
