// @implements API-001, API-002, FEA-001, BR-101, BR-402, RISK-002, RISK-004, RISK-006
import AVFoundation
import Foundation

/// Orchestrates microphone + system-audio capture. Each active source writes
/// to its own per-session WAV in real time so concurrent buffers don't trample
/// each other; on stop the two source files are mixed into one mono WAV via
/// `AudioMixer.mixFiles`. Exposes audio levels and lifecycle milestones to UI
/// consumers and enforces the BR-402 duration limit. Sources + clock are
/// injectable so tests run without hardware.
public actor DefaultAudioCaptureService: AudioCaptureService {

    private let microphoneSource: MicrophoneSource
    private let systemAudioSource: SystemAudioSource
    private let clock: AudioCaptureClock
    private let fileManager: FileManager

    private var session: ActiveSession?
    private var isStarting = false

    /// Synchronous broadcast bus for `milestones()`. Registration is sync
    /// (lock-protected) so subscribers established right before `startCapture`
    /// can never miss the early `.systemAudioFellBackToMicOnly` event.
    private let milestoneBus = MilestoneBus()

    /// Synchronous broadcast bus for `audioLevels()`. Subscribers are finished
    /// at the end of every capture so the protocol contract
    /// "terminates when the active capture ends" holds.
    private let levelBus = LevelBus()

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

        let levelBus = self.levelBus
        let micConsumer: AudioBufferConsumer = { [weak self] envelope in
            guard let self, let writer = micWriter else { return }
            self.handleBuffer(envelope.buffer, writer: writer, levelGate: levelGate, levelBus: levelBus)
        }
        let systemConsumer: AudioBufferConsumer = { [weak self] envelope in
            guard let self, let writer = systemWriter else { return }
            self.handleBuffer(envelope.buffer, writer: writer, levelGate: levelGate, levelBus: levelBus)
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
                if let systemWriter {
                    try? systemWriter.finish()
                    try? fileManager.removeItem(at: systemWriter.url)
                }
                milestoneBus.broadcast(.systemAudioFellBackToMicOnly(reason: "Screen Recording permission denied."))
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
            durationTask: nil
        )
        self.session = session
        scheduleDurationGuard(for: &session)
        self.session = session
    }

    @discardableResult
    public func stopCapture() async throws -> URL {
        try await performStop(reason: .userRequested)
    }

    private func performStop(reason: AudioCaptureFinalizationReason) async throws -> URL {
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
        // Always finish level subscribers when the capture ends, regardless
        // of whether any audio was captured. New captures must re-subscribe.
        defer { levelBus.finishAll() }

        guard totalFrames > 0 else {
            cleanupSessionFiles(session)
            throw AudioCaptureError.noAudioCaptured
        }

        let finalURL: URL
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
            finalURL = session.outputURL
        case let (mic?, nil):
            finalURL = mic.url
        case let (nil, sys?):
            finalURL = sys.url
        case (nil, nil):
            throw AudioCaptureError.noAudioCaptured
        }

        milestoneBus.broadcast(.recordingFinalized(url: finalURL, reason: reason))
        return finalURL
    }

    public nonisolated func audioLevels() -> AsyncStream<Float> { levelBus.subscribe() }
    public nonisolated func milestones() -> AsyncStream<AudioCaptureMilestone> { milestoneBus.subscribe() }

    public var isCapturing: Bool { session != nil }

    public var elapsedTime: TimeInterval {
        guard let session else { return 0 }
        return clock.now().timeIntervalSince(session.startedAt)
    }

    // MARK: Internals

    private nonisolated func handleBuffer(
        _ buffer: AVAudioPCMBuffer,
        writer: AudioFileWriter,
        levelGate: LevelGate,
        levelBus: LevelBus
    ) {
        let level = AudioLevelComputer.level(for: buffer)
        if levelGate.shouldEmit() {
            levelBus.broadcast(level)
        }
        // RISK-006: a single dropped write should not abort the capture; the
        // writer flushes incrementally so prior frames remain on disk.
        try? writer.write(buffer: buffer)
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
        milestoneBus.broadcast(milestone)
    }

    private func autoStopIfActive(sessionId: UUID) async {
        guard session?.id == sessionId else { return }
        _ = try? await performStop(reason: .durationLimitReached)
    }

    private struct ActiveSession {
        var id: UUID
        var configuration: AudioCaptureConfiguration
        var outputURL: URL
        var micWriter: AudioFileWriter?
        var systemWriter: AudioFileWriter?
        var startedAt: Date
        var durationTask: Task<Void, Never>?
    }
}

/// Thread-safe broadcast bus for `audioLevels()`. Registration is synchronous
/// so subscribers can never miss yields from a capture that started right
/// after their subscription call.
public final class LevelBus: @unchecked Sendable {
    private let lock = NSLock()
    private var observers: [(id: UUID, continuation: AsyncStream<Float>.Continuation)] = []

    public init() {}

    public func subscribe() -> AsyncStream<Float> {
        AsyncStream { continuation in
            let id = UUID()
            lock.withLock { observers.append((id, continuation)) }
            continuation.onTermination = { [weak self] _ in
                self?.unsubscribe(id: id)
            }
        }
    }

    public func broadcast(_ level: Float) {
        let snapshot: [(id: UUID, continuation: AsyncStream<Float>.Continuation)] = lock.withLock { observers }
        for entry in snapshot { entry.continuation.yield(level) }
    }

    /// Finishes all current subscribers. Called at the end of every capture
    /// so `audioLevels()` honors its "terminates on stop" contract.
    public func finishAll() {
        let snapshot: [(id: UUID, continuation: AsyncStream<Float>.Continuation)] = lock.withLock {
            let s = observers
            observers.removeAll()
            return s
        }
        for entry in snapshot { entry.continuation.finish() }
    }

    private func unsubscribe(id: UUID) {
        lock.withLock { observers.removeAll { $0.id == id } }
    }
}

/// Thread-safe broadcast bus for `milestones()`. Subscribers persist across
/// captures (milestones are a service-lifetime event log, not session-scoped).
public final class MilestoneBus: @unchecked Sendable {
    private let lock = NSLock()
    private var observers: [(id: UUID, continuation: AsyncStream<AudioCaptureMilestone>.Continuation)] = []

    public init() {}

    public func subscribe() -> AsyncStream<AudioCaptureMilestone> {
        AsyncStream { continuation in
            let id = UUID()
            lock.withLock { observers.append((id, continuation)) }
            continuation.onTermination = { [weak self] _ in
                self?.unsubscribe(id: id)
            }
        }
    }

    public func broadcast(_ milestone: AudioCaptureMilestone) {
        let snapshot: [(id: UUID, continuation: AsyncStream<AudioCaptureMilestone>.Continuation)] = lock.withLock { observers }
        for entry in snapshot { entry.continuation.yield(milestone) }
    }

    private func unsubscribe(id: UUID) {
        lock.withLock { observers.removeAll { $0.id == id } }
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
