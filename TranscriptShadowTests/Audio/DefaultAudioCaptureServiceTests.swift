// @implements TEST-001, TEST-002, TEST-004, TEST-005
import AVFoundation
import XCTest
@testable import TranscriptShadow

final class DefaultAudioCaptureServiceTests: XCTestCase {

    // MARK: TEST-001 — start/stop lifecycle

    func test_TEST_001_startThenStop_returnsValidWAV_andTogglesIsCapturing() async throws {
        let mic = FakeMicrophoneSource()
        let sys = FakeSystemAudioSource()
        let clock = FakeAudioCaptureClock()
        let service = DefaultAudioCaptureService(
            microphoneSource: mic,
            systemAudioSource: sys,
            clock: clock
        )

        var capturingFlag = await service.isCapturing
        XCTAssertFalse(capturingFlag)

        try await service.startCapture(configuration: .microphoneOnly)
        capturingFlag = await service.isCapturing
        XCTAssertTrue(capturingFlag)

        // Push a few buffers to simulate audio flowing in.
        for _ in 0..<20 {
            mic.push(SyntheticPCMBuffer.make(frameCount: 4_800, amplitude: 0.3))
        }

        let url = try await service.stopCapture()
        capturingFlag = await service.isCapturing
        XCTAssertFalse(capturingFlag)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let readback = try AVAudioFile(forReading: url)
        XCTAssertGreaterThan(readback.length, 0)

        try? FileManager.default.removeItem(at: url)
    }

    func test_startTwice_throwsCaptureAlreadyInProgress() async throws {
        let mic = FakeMicrophoneSource()
        let service = DefaultAudioCaptureService(
            microphoneSource: mic,
            systemAudioSource: FakeSystemAudioSource(),
            clock: FakeAudioCaptureClock()
        )
        try await service.startCapture(configuration: .microphoneOnly)
        mic.push(SyntheticPCMBuffer.make(frameCount: 4_800, amplitude: 0.2))
        do {
            try await service.startCapture(configuration: .microphoneOnly)
            XCTFail("Expected captureAlreadyInProgress")
        } catch let error as AudioCaptureError {
            XCTAssertEqual(error, .captureAlreadyInProgress)
        }
        let url = try await service.stopCapture()
        try? FileManager.default.removeItem(at: url)
    }

    func test_stopWithoutStart_throwsNoActiveCapture() async {
        let service = DefaultAudioCaptureService(
            microphoneSource: FakeMicrophoneSource(),
            systemAudioSource: FakeSystemAudioSource(),
            clock: FakeAudioCaptureClock()
        )
        do {
            _ = try await service.stopCapture()
            XCTFail("Expected noActiveCapture")
        } catch let error as AudioCaptureError {
            XCTAssertEqual(error, .noActiveCapture)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    // MARK: TEST-002 — audio level stream

    func test_TEST_002_audioLevels_streamEmitsValuesInUnitRange() async throws {
        let mic = FakeMicrophoneSource()
        let service = DefaultAudioCaptureService(
            microphoneSource: mic,
            systemAudioSource: FakeSystemAudioSource(),
            clock: FakeAudioCaptureClock()
        )
        let stream = service.audioLevels()

        try await service.startCapture(configuration: .microphoneOnly)

        let collectorTask = Task { () -> [Float] in
            var collected: [Float] = []
            for await level in stream {
                collected.append(level)
                if collected.count >= 3 { break }
            }
            return collected
        }

        // Push many buffers spaced with brief sleeps so the LevelGate emits at
        // least three samples (gate is ~10 Hz).
        for _ in 0..<30 {
            mic.push(SyntheticPCMBuffer.make(frameCount: 4_800, amplitude: 0.4))
            try await Task.sleep(nanoseconds: 30_000_000)
        }

        let levels = await withTimeout(seconds: 2) { await collectorTask.value }
        XCTAssertGreaterThanOrEqual(levels?.count ?? 0, 1)
        for value in levels ?? [] {
            XCTAssertGreaterThanOrEqual(value, 0)
            XCTAssertLessThanOrEqual(value, 1)
        }

        let url = try await service.stopCapture()
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: TEST-004 — duration limit guard

    func test_TEST_004_durationGuard_emitsWarningThenLimitAndAutoStops() async throws {
        let mic = FakeMicrophoneSource()
        let clock = FakeAudioCaptureClock()
        let service = DefaultAudioCaptureService(
            microphoneSource: mic,
            systemAudioSource: FakeSystemAudioSource(),
            clock: clock
        )
        let configuration = AudioCaptureConfiguration(
            captureMicrophone: true,
            captureSystemAudio: false,
            maximumDuration: 120,
            warningDuration: 110
        )
        let milestones = service.milestones()

        try await service.startCapture(configuration: configuration)
        // Add at least one frame so stopCapture does not throw noAudioCaptured.
        mic.push(SyntheticPCMBuffer.make(frameCount: 4_800, amplitude: 0.2))

        let collectorTask = Task { () -> [AudioCaptureMilestone] in
            var collected: [AudioCaptureMilestone] = []
            for await milestone in milestones {
                collected.append(milestone)
                if collected.count >= 2 { break }
            }
            return collected
        }

        // Advance past the warning, then past the hard limit.
        try await Task.sleep(nanoseconds: 50_000_000)
        clock.advance(by: 115)
        try await Task.sleep(nanoseconds: 50_000_000)
        clock.advance(by: 20) // crosses the 120 boundary

        let received = await withTimeout(seconds: 2) { await collectorTask.value } ?? []
        XCTAssertEqual(received.first, .durationWarningReached)
        XCTAssertTrue(received.contains(.durationLimitReached), "Expected durationLimitReached, got \(received)")

        // Auto-stop should have happened.
        try await Task.sleep(nanoseconds: 100_000_000)
        let stillCapturing = await service.isCapturing
        XCTAssertFalse(stillCapturing, "Service should auto-stop at duration limit (BR-402)")
    }

    // MARK: TEST-005 — fallback when system-audio permission is denied

    func test_TEST_005_systemAudioDenied_fallsBackToMicOnly() async throws {
        let mic = FakeMicrophoneSource()
        let sys = FakeSystemAudioSource()
        sys.startError = AudioCaptureError.screenRecordingPermissionDenied
        let service = DefaultAudioCaptureService(
            microphoneSource: mic,
            systemAudioSource: sys,
            clock: FakeAudioCaptureClock()
        )
        let milestones = service.milestones()

        try await service.startCapture(configuration: .default)
        mic.push(SyntheticPCMBuffer.make(frameCount: 4_800, amplitude: 0.2))

        let waitForFallback = Task { () -> AudioCaptureMilestone? in
            for await milestone in milestones {
                if case .systemAudioFellBackToMicOnly = milestone { return milestone }
            }
            return nil
        }
        let event = await withTimeout(seconds: 1) { await waitForFallback.value } ?? nil
        XCTAssertNotNil(event)

        XCTAssertTrue(mic.isStarted)
        let capturing = await service.isCapturing
        XCTAssertTrue(capturing, "Capture should remain active using microphone-only")

        let url = try await service.stopCapture()
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: Codex-flagged regressions

    func test_dualSource_mixesMicAndSystemIntoOneFile() async throws {
        let mic = FakeMicrophoneSource()
        let sys = FakeSystemAudioSource()
        let service = DefaultAudioCaptureService(
            microphoneSource: mic,
            systemAudioSource: sys,
            clock: FakeAudioCaptureClock()
        )

        try await service.startCapture(configuration: .default)
        // Mic at 0.5 amplitude, system at 0.3 — mixed sample is (0.5 + 0.3) * 0.5 = 0.4
        for _ in 0..<10 {
            mic.push(SyntheticPCMBuffer.make(frameCount: 4_800, amplitude: 0.5))
            sys.push(SyntheticPCMBuffer.make(frameCount: 4_800, amplitude: 0.3))
        }
        let url = try await service.stopCapture()
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }

        let readback = try AVAudioFile(forReading: url)
        XCTAssertGreaterThan(readback.length, 0)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: readback.processingFormat, frameCapacity: AVAudioFrameCount(readback.length)) else {
            XCTFail("could not allocate readback buffer"); return
        }
        try readback.read(into: buffer)
        // First sample should be ≈ 0.4 (mixed); a serialized non-mixed file would
        // have alternating 0.5 / 0.3 chunks. Sample the first 100 frames.
        var sumAbsDelta: Float = 0
        for i in 0..<min(100, Int(buffer.frameLength)) {
            sumAbsDelta += abs((buffer.floatChannelData?[0][i] ?? 0) - 0.4)
        }
        XCTAssertLessThan(sumAbsDelta / 100.0, 0.05, "Dual-source output should be sample-summed mix, not interleaved")
    }

    func test_concurrentStartCalls_onlyOneSucceeds() async throws {
        // Use a slow mic source so the first start() awaits long enough for a
        // second concurrent caller to enter startCapture.
        let mic = SlowFakeMicrophoneSource(startDelay: 0.2)
        let service = DefaultAudioCaptureService(
            microphoneSource: mic,
            systemAudioSource: FakeSystemAudioSource(),
            clock: FakeAudioCaptureClock()
        )

        async let first: Void = service.startCapture(configuration: .microphoneOnly)
        async let secondResult: Result<Void, Error> = {
            try? await Task.sleep(nanoseconds: 50_000_000)
            do {
                try await service.startCapture(configuration: .microphoneOnly)
                return .success(())
            } catch {
                return .failure(error)
            }
        }()

        _ = try await first
        let result = await secondResult

        switch result {
        case .success:
            XCTFail("Second concurrent startCapture should reject")
        case .failure(let error):
            XCTAssertEqual(error as? AudioCaptureError, .captureAlreadyInProgress)
        }
        mic.push(SyntheticPCMBuffer.make(frameCount: 4_800, amplitude: 0.2))
        let url = try await service.stopCapture()
        try? FileManager.default.removeItem(at: url)
    }

    func test_audioLevels_streamFinishes_whenCaptureStops() async throws {
        let mic = FakeMicrophoneSource()
        let service = DefaultAudioCaptureService(
            microphoneSource: mic,
            systemAudioSource: FakeSystemAudioSource(),
            clock: FakeAudioCaptureClock()
        )
        try await service.startCapture(configuration: .microphoneOnly)
        let stream = service.audioLevels()
        mic.push(SyntheticPCMBuffer.make(frameCount: 4_800, amplitude: 0.4))
        try await Task.sleep(nanoseconds: 150_000_000)

        let drainTask = Task { () -> Bool in
            for await _ in stream { /* drain */ }
            return true   // stream finished
        }

        let url = try await service.stopCapture()
        let finished = await withTimeout(seconds: 1) { await drainTask.value } ?? false
        XCTAssertTrue(finished, "audioLevels() must terminate when capture ends")
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: helpers

    private func withTimeout<Value: Sendable>(
        seconds: TimeInterval,
        _ work: @escaping @Sendable () async -> Value
    ) async -> Value? {
        await withTaskGroup(of: Value?.self) { group in
            group.addTask { await work() }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            let value = await group.next() ?? nil
            group.cancelAll()
            return value
        }
    }
}
