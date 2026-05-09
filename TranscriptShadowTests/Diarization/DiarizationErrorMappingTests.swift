// @implements TEST-204, API-102, INT-102
import XCTest
@testable import TranscriptShadow

/// TEST-204 (Swift half) — the exit-code matrix from EPIC-04a Phase A
/// Decision 2 must round-trip into typed `DiarizationError` cases.
///
/// EPIC-03 P2 lesson: cancellation must NEVER collapse into a generic
/// `.binaryFailed` — that's an explicit anti-pattern. The pre-catch
/// ordering in `PyannoteSidecarDiarizationService` enforces this; the
/// concurrency tests in `PyannoteSidecarDiarizationServiceTests` verify
/// it end-to-end.
final class DiarizationErrorMappingTests: XCTestCase {
    func testExitCode1MapsToAudioFileMissing() {
        let err = DiarizationError.from(exitCode: 1, stderr: "ERROR:1:audio file not found: /tmp/nope.wav")
        XCTAssertEqual(err, .audioFileMissing(reason: "audio file not found: /tmp/nope.wav"))
    }

    func testExitCode2MapsToModelLoadFailed() {
        let err = DiarizationError.from(exitCode: 2, stderr: "ERROR:2:OSError: corrupt cache")
        XCTAssertEqual(err, .modelLoadFailed(reason: "OSError: corrupt cache"))
    }

    func testExitCode3MapsToHuggingFaceAuthRequired() {
        let err = DiarizationError.from(exitCode: 3, stderr: "ERROR:3:HF auth required for pyannote/speaker-diarization-community-1: 401")
        XCTAssertEqual(err, .huggingFaceAuthRequired)
    }

    func testExitCode4MapsToOutOfMemory() {
        let err = DiarizationError.from(exitCode: 4, stderr: "ERROR:4:out of memory while diarizing")
        XCTAssertEqual(err, .outOfMemory)
    }

    func testUnknownExitCodeFallsThroughToBinaryFailed() {
        let err = DiarizationError.from(exitCode: 99, stderr: "kernel killed me")
        XCTAssertEqual(err, .binaryFailed(exitCode: 99, stderr: "kernel killed me"))
    }

    func testStderrWithoutErrorLineFallsBackToRawStderr() {
        let err = DiarizationError.from(exitCode: 2, stderr: "Traceback (most recent call last):\n  ...\nValueError: bad")
        XCTAssertEqual(err, .modelLoadFailed(reason: "Traceback (most recent call last):\n  ...\nValueError: bad"))
    }

    func testStderrWithBannerLinesBeforeErrorLine() {
        let stderr = """
        UserWarning: torch initialized
        [info] loaded model
        ERROR:2:Pipeline.from_pretrained failed
        """
        let err = DiarizationError.from(exitCode: 2, stderr: stderr)
        XCTAssertEqual(err, .modelLoadFailed(reason: "Pipeline.from_pretrained failed"))
    }

    func testParseErrorMessageHandlesEmptyStderr() {
        XCTAssertNil(DiarizationError.parseErrorMessage(from: ""))
    }

    func testParseErrorMessagePicksFirstMatchingLine() {
        let stderr = """
        ERROR:1:first
        ERROR:2:second
        """
        XCTAssertEqual(DiarizationError.parseErrorMessage(from: stderr), "first")
    }

    func testParseErrorMessageWithNoColonInBody() {
        // Malformed line — no colon after the digits. Should return nil so
        // caller falls back to raw stderr.
        XCTAssertNil(DiarizationError.parseErrorMessage(from: "ERROR:malformed"))
    }
}

/// Verify the cancelled / timeout / decodeFailed / binaryMissing paths
/// have the right localized descriptions — EPIC-07's UI surfaces these.
final class DiarizationErrorLocalizationTests: XCTestCase {
    func testCancelledHasLocalizedDescription() {
        XCTAssertNotNil(DiarizationError.cancelled.errorDescription)
    }

    func testTimeoutDescriptionContainsSeconds() {
        let desc = DiarizationError.timeout(seconds: 42).errorDescription
        XCTAssertNotNil(desc)
        XCTAssertTrue(desc!.contains("42"), "expected '42' in: \(desc!)")
    }

    func testHuggingFaceAuthMentionsHFTermsURL() {
        let desc = DiarizationError.huggingFaceAuthRequired.errorDescription ?? ""
        XCTAssertTrue(desc.contains("huggingface"), "expected HF reference in: \(desc)")
    }
}

/// Smoke test for `FakeDiarizationService` — confirms it follows the
/// protocol contract (progress(0.0) → progress(1.0) → return) and
/// reports failures correctly.
final class FakeDiarizationServiceTests: XCTestCase {
    func testFakeReturnsConfiguredSuccess() async throws {
        let result = DiarizationResult(
            version: "1.0",
            audio: AudioInfo(path: "/x", durationSeconds: 5),
            model: ModelInfo(name: "fake", revision: "v1"),
            speakers: [Speaker(id: "SPEAKER_00", totalSeconds: 5)],
            segments: [SpeakerSegment(speaker: "SPEAKER_00", start: 0, end: 5)],
            overlappingSegments: [],
            elapsedSeconds: 0.1
        )
        let fake = FakeDiarizationService(outcome: .success(result))
        let collector = ProgressCollector()
        let url = URL(fileURLWithPath: "/tmp/test.wav")

        let actual = try await fake.diarize(audioURL: url) { collector.append($0) }
        let progress = collector.snapshot()

        XCTAssertEqual(actual, result)
        XCTAssertEqual(progress.first, 0.0)
        XCTAssertEqual(progress.last, 1.0)
        XCTAssertEqual(fake.receivedAudioURLs, [url])
    }

    func testFakeThrowsConfiguredFailure() async {
        let fake = FakeDiarizationService(outcome: .failure(.outOfMemory))
        let url = URL(fileURLWithPath: "/tmp/test.wav")
        do {
            _ = try await fake.diarize(audioURL: url) { _ in }
            XCTFail("expected throw")
        } catch let e as DiarizationError {
            XCTAssertEqual(e, .outOfMemory)
        } catch {
            XCTFail("wrong error: \(error)")
        }
    }

    func testFakeRespectsCancellation() async {
        let fake = FakeDiarizationService()
        let url = URL(fileURLWithPath: "/tmp/test.wav")
        let task = Task {
            try await fake.diarize(audioURL: url) { _ in }
        }
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("expected cancellation")
        } catch is CancellationError {
            // OK
        } catch {
            XCTFail("wrong error: \(error)")
        }
    }
}

private final class ProgressCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [Double] = []

    func append(_ value: Double) {
        lock.withLock { values.append(value) }
    }

    func snapshot() -> [Double] {
        lock.withLock { values }
    }
}
