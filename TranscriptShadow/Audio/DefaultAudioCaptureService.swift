// @implements API-001, API-002, FEA-001, BR-101, BR-402, RISK-002, RISK-004, RISK-006
import AVFoundation
import Foundation

/// Orchestrates microphone + system-audio capture, mixes to a single mono WAV
/// on disk, exposes an audio-level stream for UI, and enforces the BR-402
/// duration limit. Sources are injectable so tests can substitute fakes
/// without touching real hardware.
public actor DefaultAudioCaptureService: AudioCaptureService {

    private let microphoneSource: MicrophoneSource
    private let systemAudioSource: SystemAudioSource
    private let clock: AudioCaptureClock
    private let fileManager: FileManager

    private var session: ActiveSession?

    private let levelStream: AsyncStream<Float>
    private let levelContinuation: AsyncStream<Float>.Continuation
    private let milestoneStream: AsyncStream<AudioCaptureMilestone>
    private let milestoneContinuation: AsyncStream<AudioCaptureMilestone>.Continuation

    public init(
        microphoneSource: MicrophoneSource = AVAudioEngineMicrophoneSource(),
        systemAudioSource: SystemAudioSource? = nil,
        clock: AudioCaptureClock = SystemAudioCaptureClock(),
        fileManager: FileManager = .default
    ) {
        self.microphoneSource = microphoneSource
        #if canImport(ScreenCaptureKit)
        self.systemAudioSource = systemAudioSource ?? ScreenCaptureKitSystemAudioSource()
        #else
        self.systemAudioSource = systemAudioSource ?? UnavailableSystemAudioSource()
        #endif
        self.clock = clock
        self.fileManager = fileManager

        var levelCont: AsyncStream<Float>.Continuation!
        self.levelStream = AsyncStream(bufferingPolicy: .bufferingNewest(8)) { levelCont = $0 }
        self.levelContinuation = levelCont

        var milestoneCont: AsyncStream<AudioCaptureMilestone>.Continuation!
        self.milestoneStream = AsyncStream(bufferingPolicy: .unbounded) { milestoneCont = $0 }
        self.milestoneContinuation = milestoneCont
    }

    // MARK: AudioCaptureService

    public func startCapture(configuration: AudioCaptureConfiguration) async throws {
        guard session == nil else { throw AudioCaptureError.captureAlreadyInProgress }

        guard configuration.captureMicrophone || configuration.captureSystemAudio else {
            throw AudioCaptureError.unsupportedSystemConfiguration(reason: "At least one source must be enabled.")
        }

        let outputURL = try AudioCaptureLocations.newRecordingURL(date: clock.now(), fileManager: fileManager)
        let format = try AudioMixer.outputFormat(sampleRate: configuration.sampleRate)
        let writer = try AudioFileWriter(url: outputURL, format: format)
        let levelGate = LevelGate(minimumIntervalMs: 100)

        let micConsumer: AudioBufferConsumer = { [weak self] envelope in
            guard let self else { return }
            self.handleBuffer(envelope.buffer, writer: writer, levelGate: levelGate)
        }
        let systemConsumer: AudioBufferConsumer = { [weak self] envelope in
            guard let self else { return }
            self.handleBuffer(envelope.buffer, writer: writer, levelGate: levelGate)
        }

        var startedMicrophone = false
        var startedSystemAudio = false

        if configuration.captureMicrophone {
            do {
                try await microphoneSource.start(configuration: configuration, consume: micConsumer)
                startedMicrophone = true
            } catch {
                try? writer.finish()
                try? fileManager.removeItem(at: outputURL)
                throw error
            }
        }

        if configuration.captureSystemAudio {
            do {
                try await systemAudioSource.start(configuration: configuration, consume: systemConsumer)
                startedSystemAudio = true
            } catch AudioCaptureError.screenRecordingPermissionDenied where startedMicrophone {
                milestoneContinuation.yield(.systemAudioFellBackToMicOnly(reason: "Screen Recording permission denied."))
            } catch {
                if startedMicrophone {
                    await microphoneSource.stop()
                }
                try? writer.finish()
                try? fileManager.removeItem(at: outputURL)
                throw error
            }
        }

        let started = clock.now()
        let session = ActiveSession(
            configuration: configuration,
            outputURL: outputURL,
            writer: writer,
            startedAt: started,
            microphoneActive: startedMicrophone,
            systemAudioActive: startedSystemAudio,
            durationTask: nil
        )
        self.session = session
        scheduleDurationGuard(for: session)
    }

    @discardableResult
    public func stopCapture() async throws -> URL {
        guard let session else { throw AudioCaptureError.noActiveCapture }
        self.session = nil

        session.durationTask?.cancel()

        if session.microphoneActive {
            await microphoneSource.stop()
        }
        if session.systemAudioActive {
            await systemAudioSource.stop()
        }

        try session.writer.finish()

        guard session.writer.totalFrameCount > 0 else {
            try? fileManager.removeItem(at: session.outputURL)
            throw AudioCaptureError.noAudioCaptured
        }

        return session.outputURL
    }

    public nonisolated func audioLevels() -> AsyncStream<Float> { levelStream }
    public nonisolated func milestones() -> AsyncStream<AudioCaptureMilestone> { milestoneStream }

    public var isCapturing: Bool { session != nil }

    public var elapsedTime: TimeInterval {
        guard let session else { return 0 }
        return clock.now().timeIntervalSince(session.startedAt)
    }

    // MARK: Internals

    private nonisolated func handleBuffer(
        _ buffer: AVAudioPCMBuffer,
        writer: AudioFileWriter,
        levelGate: LevelGate
    ) {
        let level = AudioLevelComputer.level(for: buffer)
        if levelGate.shouldEmit() {
            levelContinuation.yield(level)
        }
        // RISK-006: a single dropped write should not abort the capture; the
        // writer flushes incrementally so prior frames remain on disk.
        try? writer.write(buffer: buffer)
    }

    private func scheduleDurationGuard(for session: ActiveSession) {
        let configuration = session.configuration
        let warningDeadline = session.startedAt.addingTimeInterval(configuration.warningDuration)
        let limitDeadline = session.startedAt.addingTimeInterval(configuration.maximumDuration)
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.clock.sleep(until: warningDeadline)
                await self.emitMilestone(.durationWarningReached, expecting: session.outputURL)
                try await self.clock.sleep(until: limitDeadline)
                await self.emitMilestone(.durationLimitReached, expecting: session.outputURL)
                try await self.autoStopIfActive(originalURL: session.outputURL)
            } catch is CancellationError {
                // session ended normally
            } catch {
                // any clock error is non-fatal for the caller
            }
        }
        self.session = ActiveSession(
            configuration: session.configuration,
            outputURL: session.outputURL,
            writer: session.writer,
            startedAt: session.startedAt,
            microphoneActive: session.microphoneActive,
            systemAudioActive: session.systemAudioActive,
            durationTask: task
        )
    }

    private func emitMilestone(_ milestone: AudioCaptureMilestone, expecting url: URL) {
        guard session?.outputURL == url else { return }
        milestoneContinuation.yield(milestone)
    }

    private func autoStopIfActive(originalURL: URL) async throws {
        guard let session, session.outputURL == originalURL else { return }
        _ = session
        _ = try? await stopCapture()
    }

    private struct ActiveSession {
        var configuration: AudioCaptureConfiguration
        var outputURL: URL
        var writer: AudioFileWriter
        var startedAt: Date
        var microphoneActive: Bool
        var systemAudioActive: Bool
        var durationTask: Task<Void, Never>?
    }
}

/// Throttles audio-level emissions to ~10 Hz so the UI stream is bounded.
public final class LevelGate: @unchecked Sendable {
    private let minimumInterval: TimeInterval
    private var lastEmission: Date = .distantPast
    private let lock = NSLock()

    public init(minimumIntervalMs: Int = 100) {
        self.minimumInterval = TimeInterval(minimumIntervalMs) / 1_000.0
    }

    public func shouldEmit() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let now = Date()
        if now.timeIntervalSince(lastEmission) >= minimumInterval {
            lastEmission = now
            return true
        }
        return false
    }
}

/// Tiny abstraction over wall-clock + sleep so duration-guard tests can run
/// without taking real seconds. The duration guard only needs `now()` and a
/// deadline-based sleep.
public protocol AudioCaptureClock: Sendable {
    func now() -> Date
    func sleep(until: Date) async throws
}

public struct SystemAudioCaptureClock: AudioCaptureClock {
    public init() {}
    public func now() -> Date { Date() }
    public func sleep(until deadline: Date) async throws {
        let interval = deadline.timeIntervalSince(Date())
        guard interval > 0 else { return }
        try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
    }
}

#if !canImport(ScreenCaptureKit)
final class UnavailableSystemAudioSource: SystemAudioSource, @unchecked Sendable {
    func start(configuration: AudioCaptureConfiguration, consume: @escaping AudioBufferConsumer) async throws {
        throw AudioCaptureError.unsupportedSystemConfiguration(reason: "ScreenCaptureKit is not available.")
    }
    func stop() async {}
}
#endif

/// Best-effort PCM format conversion for the file writer. Capture sources
/// emit buffers in their native hardware format (e.g. 44.1 kHz stereo from a
/// MacBook mic, 48 kHz from ScreenCaptureKit). The writer only accepts the
/// configured target format, so we downmix + resample lazily.
enum AudioBufferConverter {
    static func convert(_ buffer: AVAudioPCMBuffer, to targetFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        if buffer.format == targetFormat { return buffer }
        guard let converter = AVAudioConverter(from: buffer.format, to: targetFormat) else { return nil }

        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let outputCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio + 16)
        guard let output = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputCapacity) else { return nil }

        var error: NSError?
        var fed = false
        let status = converter.convert(to: output, error: &error) { _, inputStatus in
            if fed {
                inputStatus.pointee = .noDataNow
                return nil
            }
            fed = true
            inputStatus.pointee = .haveData
            return buffer
        }
        guard status != .error, error == nil else { return nil }
        return output
    }
}
