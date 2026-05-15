// @implements TEST-201, TEST-204, API-102, INT-102
import XCTest
@testable import TranscriptShadow

/// Integration tests for the Foundation `Process` bridge. The "binary"
/// is a small shell script that imitates the EPIC-04a CLI contract.
/// Tests run on every developer machine — no pyannote install required.
///
/// EPIC-03 P2 lesson is enforced here: cancellation throws `.cancelled`,
/// never `.binaryFailed`. The relevant test is
/// `testCancellationSurfacesCancelledNotBinaryFailed`.
final class PyannoteSidecarDiarizationServiceTests: XCTestCase {

    // MARK: - Static helpers (no Process needed)

    func testParseProgressMatchesExpectedRegex() {
        XCTAssertEqual(PyannoteSidecarDiarizationService.parseProgress("PROGRESS:0.42"), 0.42)
        XCTAssertEqual(PyannoteSidecarDiarizationService.parseProgress("PROGRESS:0"), 0.0)
        XCTAssertEqual(PyannoteSidecarDiarizationService.parseProgress("PROGRESS:1"), 1.0)
        XCTAssertEqual(PyannoteSidecarDiarizationService.parseProgress("PROGRESS:0.5"), 0.5)
    }

    func testParseProgressIgnoresUnrelatedLines() {
        XCTAssertNil(PyannoteSidecarDiarizationService.parseProgress(""))
        XCTAssertNil(PyannoteSidecarDiarizationService.parseProgress("hello"))
        XCTAssertNil(PyannoteSidecarDiarizationService.parseProgress("ERROR:1:nope"))
        XCTAssertNil(PyannoteSidecarDiarizationService.parseProgress("PROGRESS:"))
        XCTAssertNil(PyannoteSidecarDiarizationService.parseProgress("PROGRESS:abc"))
    }

    /// Codex Gate 2 P1 — parseProgress must reject anything not matching
    /// the EPIC-04a contract regex `^PROGRESS:(\d+(?:\.\d+)?)$`.
    func testParseProgressRejectsLooseDoubleFormats() {
        XCTAssertNil(PyannoteSidecarDiarizationService.parseProgress("  PROGRESS:0.5"))   // leading ws
        XCTAssertNil(PyannoteSidecarDiarizationService.parseProgress("PROGRESS:0.5  "))   // trailing ws
        XCTAssertNil(PyannoteSidecarDiarizationService.parseProgress("PROGRESS:-0.5"))    // negative
        XCTAssertNil(PyannoteSidecarDiarizationService.parseProgress("PROGRESS:1e2"))     // exponent
        XCTAssertNil(PyannoteSidecarDiarizationService.parseProgress("PROGRESS:inf"))     // inf
        XCTAssertNil(PyannoteSidecarDiarizationService.parseProgress("PROGRESS:nan"))     // nan
        XCTAssertNil(PyannoteSidecarDiarizationService.parseProgress("PROGRESS:.5"))      // missing leading digit
        XCTAssertNil(PyannoteSidecarDiarizationService.parseProgress("PROGRESS:1."))      // trailing dot
        XCTAssertNil(PyannoteSidecarDiarizationService.parseProgress("PROGRESS:1.2.3"))   // double dot
    }

    // MARK: - Binary not present

    func testMissingBinaryThrowsBinaryMissing() async {
        let service = PyannoteSidecarDiarizationService(
            binaryURL: URL(fileURLWithPath: "/tmp/definitely-does-not-exist-\(UUID().uuidString)")
        )
        let audio = makeAudioStubURL()
        do {
            _ = try await service.diarize(audioURL: audio) { _ in }
            XCTFail("expected throw")
        } catch DiarizationError.binaryMissing {
            // OK
        } catch {
            XCTFail("wrong error: \(error)")
        }
    }

    // MARK: - Successful run

    func testSuccessfulRunDecodesJSONAndForwardsProgress() async throws {
        let goldenPath = try Self.fixturePath(named: "golden-3spk.json")
        let goldenJSON = try String(contentsOfFile: goldenPath, encoding: .utf8)

        let binary = try FakeDiarizeBinary.writing(
            json: goldenJSON,
            progressLines: [0.1, 0.4, 0.8],
            exitCode: 0
        )
        addTeardownBlock { try? FileManager.default.removeItem(at: binary.url) }

        let service = PyannoteSidecarDiarizationService(binaryURL: binary.url)
        let collector = ProgressCollector()
        let audio = makeAudioStubURL()

        let result = try await service.diarize(audioURL: audio) { collector.append($0) }

        XCTAssertEqual(result.version, "1.0")
        XCTAssertEqual(result.speakers.count, 3)
        XCTAssertEqual(result.segments.count, 6)

        let progress = collector.snapshot()
        XCTAssertEqual(progress.first, 0.0)
        XCTAssertEqual(progress.last, 1.0)
        // Should have caught at least the 3 binary-emitted lines plus the 0.0 / 1.0 bookends.
        XCTAssertGreaterThanOrEqual(progress.count, 4)
    }

    // MARK: - Exit-code mapping (TEST-204)

    func testExitCode1MapsToAudioFileMissing() async throws {
        try await assertExitCodeMapsToError(1, expecting: .audioFileMissing(reason: "no audio")) {
            "ERROR:1:no audio"
        }
    }

    func testExitCode2MapsToModelLoadFailed() async throws {
        try await assertExitCodeMapsToError(2, expecting: .modelLoadFailed(reason: "corrupt cache")) {
            "ERROR:2:corrupt cache"
        }
    }

    func testExitCode3MapsToHuggingFaceAuthRequired() async throws {
        try await assertExitCodeMapsToError(3, expecting: .huggingFaceAuthRequired) {
            "ERROR:3:HF auth required"
        }
    }

    func testExitCode4MapsToOutOfMemory() async throws {
        try await assertExitCodeMapsToError(4, expecting: .outOfMemory) {
            "ERROR:4:OOM"
        }
    }

    func testUnknownExitCodeFallsThroughToBinaryFailed() async throws {
        let binary = try FakeDiarizeBinary.crashingWith(exitCode: 42, stderr: "kernel killed me")
        addTeardownBlock { try? FileManager.default.removeItem(at: binary.url) }

        let service = PyannoteSidecarDiarizationService(binaryURL: binary.url)
        let audio = makeAudioStubURL()
        do {
            _ = try await service.diarize(audioURL: audio) { _ in }
            XCTFail("expected throw")
        } catch DiarizationError.binaryFailed(let exitCode, let stderr) {
            XCTAssertEqual(exitCode, 42)
            XCTAssertTrue(stderr.contains("kernel killed me"))
        } catch {
            XCTFail("wrong error: \(error)")
        }
    }

    // MARK: - Cancellation (EPIC-03 P2 lesson)

    func testCancellationSurfacesCancelledNotBinaryFailed() async throws {
        let binary = try FakeDiarizeBinary.hanging(forSeconds: 60)
        addTeardownBlock { try? FileManager.default.removeItem(at: binary.url) }

        // Use a long timeout so a `.cancelled` outcome cannot be reached
        // via the timeout branch — Codex Gate 2 P2 (2026-05-09).
        let service = PyannoteSidecarDiarizationService(
            binaryURL: binary.url,
            timeoutSeconds: 600
        )
        let audio = makeAudioStubURL()
        let started = Date()
        let task = Task {
            try await service.diarize(audioURL: audio) { _ in }
        }
        try await Task.sleep(nanoseconds: 200_000_000) // 200 ms — let the process actually start
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("expected throw")
        } catch DiarizationError.cancelled {
            // OK — exactly the case EPIC-03 P2 says must not collapse.
        } catch DiarizationError.binaryFailed(let code, _) {
            XCTFail("Cancellation collapsed into .binaryFailed(\(code)) — EPIC-03 P2 regression")
        } catch DiarizationError.timeout(let s) {
            XCTFail("Cancellation reached the timeout branch (after \(s)s) — bug in cancel/timeout split")
        } catch {
            XCTFail("wrong error: \(error)")
        }

        // Tighter assertion: with timeoutSeconds=600, the only way to
        // finish quickly is via the cancellation path. If the test ran
        // for ≥10 s it almost certainly did NOT short-circuit on cancel.
        let elapsed = Date().timeIntervalSince(started)
        XCTAssertLessThan(elapsed, 10.0,
            "Cancellation took \(elapsed)s — did not short-circuit on cancel")
    }

    // MARK: - Timeout

    func testTimeoutSurfacesTimeoutError() async throws {
        let binary = try FakeDiarizeBinary.hanging(forSeconds: 30)
        addTeardownBlock { try? FileManager.default.removeItem(at: binary.url) }

        let service = PyannoteSidecarDiarizationService(
            binaryURL: binary.url,
            timeoutSeconds: 1.0
        )
        let audio = makeAudioStubURL()
        do {
            _ = try await service.diarize(audioURL: audio) { _ in }
            XCTFail("expected throw")
        } catch DiarizationError.timeout(let seconds) {
            XCTAssertEqual(seconds, 1.0, accuracy: 0.01)
        } catch {
            XCTFail("wrong error: \(error)")
        }
    }

    // MARK: - Concurrency serialization

    func testConcurrentCallsAreSerialized() async throws {
        let goldenPath = try Self.fixturePath(named: "golden-1spk.json")
        let goldenJSON = try String(contentsOfFile: goldenPath, encoding: .utf8)

        // Fake binary sleeps 0.5 s before writing — gives us a clear
        // overlap window to detect.
        let binary = try FakeDiarizeBinary.writing(
            json: goldenJSON,
            progressLines: [0.5],
            exitCode: 0,
            sleepBefore: 0.5
        )
        addTeardownBlock { try? FileManager.default.removeItem(at: binary.url) }

        let service = PyannoteSidecarDiarizationService(binaryURL: binary.url)
        let audio = makeAudioStubURL()

        let start = Date()
        async let r1 = service.diarize(audioURL: audio) { _ in }
        async let r2 = service.diarize(audioURL: audio) { _ in }
        async let r3 = service.diarize(audioURL: audio) { _ in }
        _ = try await (r1, r2, r3)
        let elapsed = Date().timeIntervalSince(start)

        // Three serial 0.5 s calls = ≥ 1.5 s. Concurrent (broken) would
        // be ≈ 0.5 s. We use 1.2 s as the lower bound to absorb spawn /
        // teardown overhead on slower runners.
        XCTAssertGreaterThanOrEqual(
            elapsed,
            1.2,
            "Three diarize() calls completed in \(elapsed)s — queue is not serializing"
        )
    }

    // MARK: - Helpers

    private func assertExitCodeMapsToError(
        _ exitCode: Int32,
        expecting expected: DiarizationError,
        stderrLine: () -> String,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let binary = try FakeDiarizeBinary.crashingWith(exitCode: exitCode, stderr: stderrLine())
        addTeardownBlock { try? FileManager.default.removeItem(at: binary.url) }

        let service = PyannoteSidecarDiarizationService(binaryURL: binary.url)
        let audio = makeAudioStubURL()
        do {
            _ = try await service.diarize(audioURL: audio) { _ in }
            XCTFail("expected throw", file: file, line: line)
        } catch let err as DiarizationError {
            XCTAssertEqual(err, expected, file: file, line: line)
        } catch {
            XCTFail("wrong error: \(error)", file: file, line: line)
        }
    }

    private func makeAudioStubURL() -> URL {
        // Tests don't actually read this file; the fake binary parses
        // --audio out of args and ignores the path.
        FileManager.default.temporaryDirectory.appendingPathComponent("stub-\(UUID().uuidString).wav")
    }

    private static func fixturePath(named name: String) throws -> String {
        let thisFile = URL(fileURLWithPath: #filePath)
        let repoRoot = thisFile
            .deletingLastPathComponent()  // Diarization/
            .deletingLastPathComponent()  // TranscriptShadowTests/
            .deletingLastPathComponent()  // repo root
        let url = repoRoot
            .appendingPathComponent("sidecar")
            .appendingPathComponent("test_fixtures")
            .appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw NSError(
                domain: "PyannoteSidecarDiarizationServiceTests",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "fixture not found at \(url.path)"]
            )
        }
        return url.path
    }
}

// MARK: - FakeDiarizeBinary

/// Builder for a small `/bin/sh` script that imitates the EPIC-04a CLI
/// contract — parses `--audio` / `--output`, emits PROGRESS lines on
/// stdout, optionally writes a JSON file to `--output`, optionally
/// emits a stderr line, and exits with a configured code.
private struct FakeDiarizeBinary {
    let url: URL

    static func writing(
        json: String,
        progressLines: [Double] = [0.1, 0.5],
        exitCode: Int32 = 0,
        stderr: String = "",
        sleepBefore: Double = 0
    ) throws -> FakeDiarizeBinary {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent("fake-diarize-\(UUID().uuidString).sh")

        let progressEchoes = progressLines
            .map { "echo \"PROGRESS:\(String(format: "%.2f", $0))\"" }
            .joined(separator: "\n")

        let stderrLine = stderr.isEmpty
            ? ""
            : "echo \(shellQuoted(stderr)) >&2"

        let sleepLine = sleepBefore > 0
            ? "sleep \(sleepBefore)"
            : ""

        let script = """
        #!/bin/sh
        OUTPUT=""
        while [ $# -gt 0 ]; do
          case "$1" in
            --output) OUTPUT="$2"; shift 2 ;;
            --audio) shift 2 ;;
            --num-speakers) shift 2 ;;
            --hf-token) shift 2 ;;
            --model) shift 2 ;;
            *) shift ;;
          esac
        done
        \(progressEchoes)
        \(sleepLine)
        cat > "$OUTPUT" <<'__DIARIZE_FAKE_EOF__'
        \(json)
        __DIARIZE_FAKE_EOF__
        \(stderrLine)
        exit \(exitCode)
        """

        try script.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o755))],
            ofItemAtPath: url.path
        )
        return FakeDiarizeBinary(url: url)
    }

    static func crashingWith(exitCode: Int32, stderr: String) throws -> FakeDiarizeBinary {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent("fake-diarize-\(UUID().uuidString).sh")
        let stderrLine = stderr.isEmpty
            ? ""
            : "echo \(shellQuoted(stderr)) >&2"
        let script = """
        #!/bin/sh
        \(stderrLine)
        exit \(exitCode)
        """
        try script.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o755))],
            ofItemAtPath: url.path
        )
        return FakeDiarizeBinary(url: url)
    }

    static func hanging(forSeconds: Int = 60) throws -> FakeDiarizeBinary {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent("fake-diarize-\(UUID().uuidString).sh")
        // Honor SIGTERM so cancellation flow is exercised cleanly. exit
        // 130 is what shells use for "terminated by SIGINT/SIGTERM".
        let script = """
        #!/bin/sh
        trap 'exit 130' TERM
        sleep \(forSeconds)
        """
        try script.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o755))],
            ofItemAtPath: url.path
        )
        return FakeDiarizeBinary(url: url)
    }

    private static func shellQuoted(_ s: String) -> String {
        // Single-quote the string and escape embedded single quotes.
        let escaped = s.replacingOccurrences(of: "'", with: #"'"'"'"#)
        return "'\(escaped)'"
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
