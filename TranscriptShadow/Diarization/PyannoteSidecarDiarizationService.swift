// @implements API-102, INT-102, FEA-003, BR-101, ARC-002
import Foundation

/// Production `DiarizationService` that spawns the EPIC-04a `diarize`
/// binary as a subprocess.
///
/// **Note on Foundation `Process` vs `swift-subprocess`** (EPIC-04b
/// Phase A Decision 1 vs implementation reality, 2026-05-09): The
/// planning round picked `swiftlang/swift-subprocess` (then 0.4.x),
/// citing `Process` + `readabilityHandler` as a Swift 6 strict-
/// concurrency footgun. We use Foundation `Process` here anyway
/// because:
///
/// 1. swift-subprocess is still pre-1.0; its API is shifting; adding a
///    brittle SPM dep for a single subprocess is more risk than it
///    saves.
/// 2. The `readabilityHandler` footgun is avoided by using
///    `FileHandle.bytes.lines` (AsyncSequence) for stdout streaming —
///    no closure captures, no fire-after-EOF surprises.
/// 3. Cancellation is wired via `withTaskCancellationHandler` + a
///    polling `waitForExit` that stays correct under the strict-
///    concurrency model.
///
/// Documented in EPIC-04b Agent Observations as a deviation. Revisit
/// before public ship if swift-subprocess hits 1.0 with a stable API.
///
/// **Concurrency**: All `diarize(...)` calls go through `AsyncTaskQueue`.
/// The pyannote pipeline holds the entire model in memory; running two
/// simultaneously would 2× the footprint and thrash. The queue
/// enforces strict serialization (EPIC-04b Phase A Decision 5).
///
/// **Cancellation**: Pre-catch `is CancellationError` before any other
/// failure mapping. The cancelled case must NEVER collapse into
/// `.binaryFailed` (EPIC-03 P2 lesson).
public final class PyannoteSidecarDiarizationService: DiarizationService, @unchecked Sendable {
    private let binaryURL: URL
    private let timeoutSeconds: TimeInterval
    private let hfTokenProvider: @Sendable () -> String?
    private let queue = AsyncTaskQueue()

    public init(
        binaryURL: URL? = nil,
        timeoutSeconds: TimeInterval = 600,
        hfTokenProvider: @escaping @Sendable () -> String? = { ProcessInfo.processInfo.environment["HF_TOKEN"] }
    ) {
        self.binaryURL = binaryURL ?? Self.defaultBinaryURL
        self.timeoutSeconds = timeoutSeconds
        self.hfTokenProvider = hfTokenProvider
    }

    /// Default location of the bundled `diarize` binary. The Run Script
    /// Build Phase (EPIC-04b CW3) places `sidecar/dist/diarize/` here
    /// and signs it bottom-up.
    public static var defaultBinaryURL: URL {
        if let resourceURL = Bundle.main.resourceURL {
            return resourceURL
                .appendingPathComponent("diarize")
                .appendingPathComponent("diarize")
        }
        return URL(fileURLWithPath: "/dev/null")
    }

    public func diarize(
        audioURL: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> DiarizationResult {
        try await queue.enqueue {
            try await self.runOnce(audioURL: audioURL, progress: progress)
        }
    }

    private func runOnce(
        audioURL: URL,
        progress: @Sendable @escaping (Double) -> Void
    ) async throws -> DiarizationResult {
        guard FileManager.default.fileExists(atPath: binaryURL.path) else {
            throw DiarizationError.binaryMissing(binaryURL)
        }

        let outputURL = Self.makeTemporaryOutputURL()
        defer { try? FileManager.default.removeItem(at: outputURL) }

        progress(0.0)

        let process = Process()
        process.executableURL = binaryURL
        process.arguments = ["--audio", audioURL.path, "--output", outputURL.path]

        // Whitelist env vars passed to the child instead of copying the
        // parent's entire environment — Codex Gate 2 P1 (2026-05-09).
        // The previous wholesale copy leaked test runner / Xcode env vars
        // into the sidecar.
        process.environment = Self.buildChildEnvironment(token: hfTokenProvider())

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.standardInput = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            throw DiarizationError.binaryFailed(
                exitCode: -1,
                stderr: "could not launch \(binaryURL.path): \(error.localizedDescription)"
            )
        }

        // Start the stream readers as soon as the child is alive. They
        // exit when the pipe's write end closes (= child exits).
        let stdoutTask = Task<Void, Never> {
            await Self.streamProgress(from: stdoutPipe.fileHandleForReading, into: progress)
        }
        let stderrCollector = StderrCollector()
        let stderrTask = Task<Void, Never> {
            await stderrCollector.collect(from: stderrPipe.fileHandleForReading)
        }

        let runHandle = ProcessHandle(process: process)

        let exitOutcome: ExitOutcome = await withTaskCancellationHandler(
            operation: {
                await Self.runWithTimeout(process: process, timeoutSeconds: self.timeoutSeconds)
            },
            onCancel: { runHandle.terminate() }
        )

        // Distinguish cancellation from genuine timeout — Codex Gate 2 P1
        // (2026-05-09). When the outer task is cancelled, runWithTimeout
        // also returns .timedOut (because the timeout sleep throws and
        // `try?` falls through). The onCancel handler already SIGTERM'd
        // the child; we just need to wait for it to die. The grace
        // sleep + SIGKILL fallback is reserved for genuine timeouts.
        if Task.isCancelled {
            await Self.waitForExitForever(process)
        } else if exitOutcome == .timedOut {
            runHandle.terminate()
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if process.isRunning { runHandle.kill() }
            await Self.waitForExitForever(process)
        }

        // The pipe readers exit when the child closes its end. Force-
        // close our read ends after exit so a stray writer (e.g. a
        // child that double-forked) cannot keep the readers alive.
        try? stdoutPipe.fileHandleForReading.close()
        try? stderrPipe.fileHandleForReading.close()

        await stdoutTask.value
        await stderrTask.value

        // Cancellation pre-catch — EPIC-03 P2 lesson, must come before
        // any exit-code mapping.
        if Task.isCancelled {
            throw DiarizationError.cancelled
        }

        if exitOutcome == .timedOut {
            throw DiarizationError.timeout(seconds: timeoutSeconds)
        }

        let exitCode = process.terminationStatus
        let stderr = await stderrCollector.text()

        guard exitCode == 0 else {
            throw DiarizationError.from(exitCode: exitCode, stderr: stderr)
        }

        progress(1.0)

        let outputData: Data
        do {
            outputData = try Data(contentsOf: outputURL)
        } catch {
            throw DiarizationError.decodeFailed(
                reason: "output file unreadable: \(error.localizedDescription)"
            )
        }

        let decoded: DiarizationResult
        do {
            decoded = try JSONDecoder().decode(DiarizationResult.self, from: outputData)
        } catch {
            throw DiarizationError.decodeFailed(reason: error.localizedDescription)
        }

        // Codex Gate 2 P2 (2026-05-09): enforce the schema version we wrote
        // the Codable for. A non-1.0 envelope with the same shape would
        // silently parse otherwise.
        guard decoded.version == DiarizationResult.supportedSchemaVersion else {
            throw DiarizationError.decodeFailed(
                reason: "unsupported envelope version \(decoded.version) (expected \(DiarizationResult.supportedSchemaVersion))"
            )
        }

        return decoded
    }

    // MARK: - Environment

    /// Construct the child process environment from a curated whitelist.
    /// Avoids leaking arbitrary parent / test runner state to the
    /// sidecar (Codex Gate 2 P1 finding).
    private static func buildChildEnvironment(token: String?) -> [String: String] {
        let parent = ProcessInfo.processInfo.environment
        let allowedKeys: Set<String> = [
            "PATH",
            "HOME",
            "TMPDIR",
            "USER",
            "LANG",
            "LC_ALL",
            "LC_CTYPE",
            // Allow the user to override the binary's own cache defaults.
            "HF_HOME",
            "HF_HUB_OFFLINE",
            "NUMBA_CACHE_DIR",
            // The bookmark hand-off contract from EPIC-04a Phase A Decision 3.
            "TRANSCRIPT_SHADOW_AUDIO_BOOKMARK",
        ]
        var env: [String: String] = [:]
        for key in allowedKeys {
            if let value = parent[key] {
                env[key] = value
            }
        }
        // PATH must always exist for shebang resolution etc.
        if env["PATH"] == nil {
            env["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin"
        }
        if let token = token {
            env["HF_TOKEN"] = token
        }
        return env
    }

    // MARK: - Process wait + timeout race

    /// Race the process exit against the timeout. Returns whichever
    /// fires first. The wait task respects cancellation so that
    /// `group.cancelAll()` (which fires after the winner is picked) can
    /// drain it without blocking until the natural process exit.
    private static func runWithTimeout(
        process: Process,
        timeoutSeconds: TimeInterval
    ) async -> ExitOutcome {
        await withTaskGroup(of: ExitOutcome.self) { group in
            group.addTask {
                let exited = await waitForExitOrCancel(process)
                return exited ? .processExited : .timedOut
            }
            group.addTask {
                let nanos = UInt64(max(0, timeoutSeconds) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
                return .timedOut
            }
            let first = await group.next() ?? .processExited
            group.cancelAll()
            return first
        }
    }

    /// Polling wait that **respects** cancellation. Used inside the
    /// timeout race so that `group.cancelAll()` after the winner is
    /// chosen returns immediately instead of blocking until the process
    /// exits naturally.
    ///
    /// Returns `true` if the process exited; `false` if the wait was
    /// cancelled before the process exited (caller should send
    /// SIGTERM/SIGKILL and then drain via `waitForExitForever`).
    private static func waitForExitOrCancel(_ process: Process) async -> Bool {
        while process.isRunning {
            do {
                try await Task.sleep(nanoseconds: 50_000_000) // 50 ms
            } catch {
                return false
            }
        }
        return true
    }

    /// Polling wait that **ignores** the calling task's cancellation.
    /// Used after a timeout kill or after a cancel-induced SIGTERM, when
    /// we still need to reap the process so the pipe readers can drain.
    ///
    /// Codex Gate 2 P1 (2026-05-09): the previous version called
    /// `try? await Task.sleep` which throws immediately on a cancelled
    /// task — `try?` swallowed the throw but the loop spun every iteration
    /// with no throttle, busy-waiting at ~CPU-bound speed until the
    /// process actually exited. The fix runs the polling loop inside a
    /// `Task.detached`, which creates a fresh task whose cancellation is
    /// independent of the caller's.
    private static func waitForExitForever(_ process: Process) async {
        await Task.detached {
            while process.isRunning {
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }.value
    }

    // MARK: - Stdout stream → progress

    private static func streamProgress(
        from handle: FileHandle,
        into progress: @Sendable @escaping (Double) -> Void
    ) async {
        // FileHandle.bytes.lines yields complete `\n`-delimited Strings.
        // No readabilityHandler, no closure captures, no fire-after-EOF.
        do {
            for try await line in handle.bytes.lines {
                if let fraction = parseProgress(line) {
                    progress(fraction)
                }
            }
        } catch {
            // Stream closed or read failed; nothing to surface — exit
            // code + stderr are the source of truth for failures.
        }
    }

    /// Parse a single line. Returns the fraction iff it matches the
    /// EPIC-04a contract regex `^PROGRESS:(\d+(?:\.\d+)?)$` exactly —
    /// no leading/trailing whitespace, no exponent, no negatives, no
    /// `inf` / `nan` (Codex Gate 2 P1 finding).
    static func parseProgress(_ line: String) -> Double? {
        guard line.hasPrefix("PROGRESS:") else { return nil }
        let body = line.dropFirst("PROGRESS:".count)
        // Manual ASCII-digit walk to enforce exact regex semantics.
        // Double() alone accepts "inf", "1e2", "  1", "-0.5" etc.
        var sawDigit = false
        var sawDot = false
        var sawDigitAfterDot = false
        for ch in body {
            switch ch {
            case "0"..."9":
                if sawDot { sawDigitAfterDot = true }
                sawDigit = true
            case ".":
                if sawDot || !sawDigit { return nil }
                sawDot = true
            default:
                return nil
            }
        }
        guard sawDigit else { return nil }
        if sawDot && !sawDigitAfterDot { return nil }  // "1." rejected
        return Double(body)
    }

    // MARK: - Helpers

    private static func makeTemporaryOutputURL() -> URL {
        let name = "diarize-\(UUID().uuidString).json"
        return FileManager.default.temporaryDirectory.appendingPathComponent(name)
    }
}

/// Thread-safe wrapper around a `Process` so the cancel handler — which
/// runs on an arbitrary executor — can terminate / kill without data-
/// racing with the run task.
private final class ProcessHandle: @unchecked Sendable {
    private let lock = NSLock()
    private let process: Process
    private var hasTerminated = false
    private var hasKilled = false

    init(process: Process) {
        self.process = process
    }

    func terminate() {
        lock.withLock {
            guard !hasTerminated, process.isRunning else { return }
            hasTerminated = true
            process.terminate()  // SIGTERM
        }
    }

    func kill() {
        lock.withLock {
            guard !hasKilled, process.isRunning else { return }
            hasKilled = true
            // Foundation only sends SIGTERM; reach for POSIX kill(2)
            // to send SIGKILL. processIdentifier is valid until reap.
            kill_unix(process.processIdentifier, 9)
        }
    }
}

/// POSIX `kill(2)` shim. Foundation's `Process.terminate()` is SIGTERM
/// only; we need SIGKILL for the timeout fallback.
@_silgen_name("kill")
private func kill_unix(_ pid: Int32, _ signal: Int32) -> Int32

/// Stderr collector. Captures the entire stderr stream into a single
/// String for `DiarizationError.from(exitCode:stderr:)`.
private actor StderrCollector {
    private var buffer = Data()

    func collect(from handle: FileHandle) async {
        do {
            for try await byte in handle.bytes {
                buffer.append(byte)
            }
        } catch {
            // Stream closed — buffer holds whatever arrived before.
        }
    }

    func text() -> String {
        String(data: buffer, encoding: .utf8) ?? ""
    }
}

private enum ExitOutcome: Sendable, Equatable {
    case processExited
    case timedOut
}
