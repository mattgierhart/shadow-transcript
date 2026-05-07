// @implements API-001, API-002, FEA-001, BR-101, BR-402, RISK-002, RISK-004, RISK-006
import AVFoundation
import Foundation

/// Orchestrates microphone + system-audio capture. Each active source writes
/// to its own per-session WAV in real time so concurrent buffers don't trample
/// each other; on stop the two source files are mixed into one mono WAV via
/// `AudioMixer.mixFiles`. Exposes an audio-level stream for UI and enforces
/// the BR-402 duration limit. Sources + clock are injectable so tests run
/// without hardware.
public actor DefaultAudioCaptureService: AudioCaptureService {

    private let microphoneSource: MicrophoneSource
    private let systemAudioSource: SystemAudioSource
    private let clock: AudioCaptureClock
    private let fileManager: FileManager

    private var session: ActiveSession?
    private var isStarting = false

    private var levelObservers: [AsyncStream<Float>.Continuation] = []
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

        var milestoneCont: AsyncStream<AudioCaptureMilestone>.Continuation!
        self.milestoneStream = AsyncStream(bufferingPolicy: .unbounded) { milestoneCont = $0 }
        self.milestoneContinuation = milestoneCont
    }

    // MARK: AudioCaptureService

    public func startCapture(configuration: AudioCaptureConfiguration) async throws {
        guard !isStarting, session == nil else {
            throw AudioCaptureError.captureAlreadyInProgress
        }
        guard configuration.captureMicrophone || configuration.captureSystemAudio else {
            throw AudioCaptureError.unsupportedSystemConfiguration(reason: "At least one source must be enabled.")
        }
        isStarting = true
        defer { isStarting = false }

        let outputURL = try AudioCaptureLocations.newRecordingURL(date: clock.now(), fileManager: fileManager)
        let format = try AudioMixer.outputFormat(sampleRate: configuration.sampleRate)
        let levelGate = LevelGate(minimumIntervalMs: 100)
        let dualSource = configuration.captureMicrophone && configuration.captureSystemAudio

        let micWriter: AudioFileWriter?
        let systemWriter: AudioFileWriter?

        if dualSource {
            let micPart = outputURL.deletingPathExtension().appendingPathExtension("mic.wav")
            let sysPart = outputURL.deletingPathExtension().appendingPathExtension("sys.wav")
            micWriter = try AudioFileWriter(url: micPart, format: format)
            systemWriter = try AudioFileWriter(url: sysPart, format: format)
        } else if configuration.captureMicrophone {
            micWriter = try AudioFileWriter(url: outputURL, format: format)
            systemWriter = nil
        } else {
            micWriter = nil
            systemWriter = try AudioFileWriter(url: outputURL, format: format)
        }

        let micConsumer: AudioBufferConsumer = { [weak self] envelope in
            guard let self, let writer = micWriter else { return }
            self.handleBuffer(envelope.buffer, writer: writer, levelGate: levelGate)
        }
        let systemConsumer: AudioBufferConsumer = { [weak self] envelope in
            guard let self, let writer = systemWriter else { return }
            self.handleBuffer(envelope.buffer, writer: writer, levelGate: levelGate)
        }

        var startedMicrophone = false
        var startedSystemAudio = false

        if configuration.captureMicrophone {
            do {
                try await microphoneSource.start(configuration: configuration, consume: micConsumer)
                startedMicrophone = true
            } catch {
                cleanupOnStartFailure(writers: [micWriter, systemWriter])
                throw error
            }
        }

        if configuration.captureSystemAudio {
            do {
                try await systemAudioSource.start(configuration: configuration, consume: systemConsumer)
                startedSystemAudio = true
            } catch AudioCaptureError.screenRecordingPermissionDenied where startedMicrophone {
                // Discard the unused system writer; mic-only proceeds.
                if let systemWriter {
                    try? systemWriter.finish()
                    try? fileManager.removeItem(at: systemWriter.url)
                }
                milestoneContinuation.yield(.systemAudioFellBackToMicOnly(reason: "Screen Recording permission denied."))
            } catch {
                if startedMicrophone { await microphoneSource.stop() }
                cleanupOnStartFailure(writers: [micWriter, systemWriter])
                throw error
            }
        }

        let started = clock.now()
        var session = ActiveSession(
            id: UUID(),
            configuration: configuration,
            outputURL: outputURL,
            micWriter: startedMicrophone ? micWriter : nil,
            systemWriter: startedSystemAudio ? systemWriter : nil,
            startedAt: started,
            durationTask: nil,
            levelObservers: levelObservers
        )
        // Hand off observers to the session so stop() can finish them.
        levelObservers.removeAll()
        self.session = session
        scheduleDurationGuard(for: &session)
        self.session = session
    }

    @discardableResult
    public func stopCapture() async throws -> URL {
        guard var session else { throw AudioCaptureError.noActiveCapture }
        self.session = nil
        session.durationTask?.cancel()

        if session.micWriter != nil {
            await microphoneSource.stop()
        }
        if session.systemWriter != nil {
            await systemAudioSource.stop()
        }

        try session.micWriter?.finish()
        try session.systemWriter?.finish()

        let totalFrames = (session.micWriter?.totalFrameCount ?? 0)
            + (session.systemWriter?.totalFrameCount ?? 0)
        defer { finishLevelObservers(session.levelObservers) }

        guard totalFrames > 0 else {
            cleanupSessionFiles(session)
            throw AudioCaptureError.noAudioCaptured
        }

        switch (session.micWriter, session.systemWriter) {
        case let (mic?, sys?):
            do {
                try AudioMixer.mixFiles(microphoneFile: mic.url, systemFile: sys.url, to: session.outputURL)
            } catch {
                cleanupSessionFiles(session)
                throw error
            }
            try? fileManager.removeItem(at: mic.url)
            try? fileManager.removeItem(at: sys.url)
            return session.outputURL
        case let (mic?, nil):
            return mic.url
        case let (nil, sys?):
            return sys.url
        case (nil, nil):
            throw AudioCaptureError.noAudioCaptured
        }
    }

    public nonisolated func audioLevels() -> AsyncStream<Float> {
        AsyncStream { continuation in
            Task { await self.registerLevelObserver(continuation) }
        }
    }

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
            Task { await self.broadcastLevel(level) }
        }
        // RISK-006: a single dropped write should not abort the capture; the
        // writer flushes incrementally so prior frames remain on disk.
        try? writer.write(buffer: buffer)
    }

    private func registerLevelObserver(_ continuation: AsyncStream<Float>.Continuation) {
        if var current = session {
            current.levelObservers.append(continuation)
            session = current
        } else {
            levelObservers.append(continuation)
        }
    }

    private func broadcastLevel(_ level: Float) {
        if let current = session {
            for observer in current.levelObservers { observer.yield(level) }
        } else {
            for observer in levelObservers { observer.yield(level) }
        }
    }

    private nonisolated func finishLevelObservers(_ observers: [AsyncStream<Float>.Continuation]) {
        for observer in observers { observer.finish() }
    }

    private func cleanupOnStartFailure(writers: [AudioFileWriter?]) {
        for writer in writers.compactMap({ $0 }) {
            try? writer.finish()
            try? fileManager.removeItem(at: writer.url)
        }
    }

    private func cleanupSessionFiles(_ session: ActiveSession) {
        if let mic = session.micWriter { try? fileManager.removeItem(at: mic.url) }
        if let sys = session.systemWriter { try? fileManager.removeItem(at: sys.url) }
        try? fileManager.removeItem(at: session.outputURL)
    }

    private func scheduleDurationGuard(for session: inout ActiveSession) {
        let configuration = session.configuration
        let warningDeadline = session.startedAt.addingTimeInterval(configuration.warningDuration)
        let limitDeadline = session.startedAt.addingTimeInterval(configuration.maximumDuration)
        let sessionId = session.id
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.clock.sleep(until: warningDeadline)
                await self.emitMilestoneIfActive(.durationWarningReached, sessionId: sessionId)
                try await self.clock.sleep(until: limitDeadline)
                await self.emitMilestoneIfActive(.durationLimitReached, sessionId: sessionId)
                await self.autoStopIfActive(sessionId: sessionId)
            } catch is CancellationError {
                // session ended normally
            } catch {
                // any clock error is non-fatal for the caller
            }
        }
        session.durationTask = task
    }

    private func emitMilestoneIfActive(_ milestone: AudioCaptureMilestone, sessionId: UUID) {
        guard session?.id == sessionId else { return }
        milestoneContinuation.yield(milestone)
    }

    private func autoStopIfActive(sessionId: UUID) async {
        guard session?.id == sessionId else { return }
        _ = try? await stopCapture()
    }

    private struct ActiveSession {
        var id: UUID
        var configuration: AudioCaptureConfiguration
        var outputURL: URL
        var micWriter: AudioFileWriter?
        var systemWriter: AudioFileWriter?
        var startedAt: Date
        var durationTask: Task<Void, Never>?
        var levelObservers: [AsyncStream<Float>.Continuation]
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
        lock.withLock {
            let now = Date()
            if now.timeIntervalSince(lastEmission) >= minimumInterval {
                lastEmission = now
                return true
            }
            return false
        }
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
        if buffer.format.isEquivalent(to: targetFormat) { return buffer }
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
