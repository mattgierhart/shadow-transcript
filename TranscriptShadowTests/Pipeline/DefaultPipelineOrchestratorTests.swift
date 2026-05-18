// @implements ARC-001, ARC-003, API-301, TEST-501, TEST-502
// Tests for the EPIC-08 PipelineOrchestrator. Covers the happy path,
// cancel propagation, error short-circuit, auto-export branch, export
// failure (non-fatal), monotonic progress, and the cleanup discipline
// (TEST-501 + TEST-502).

import XCTest
@testable import TranscriptShadow

@MainActor
final class DefaultPipelineOrchestratorTests: XCTestCase {
    private struct DeliberateError: Error, LocalizedError {
        let errorDescription: String? = "Deliberate failure"
    }

    /// Counting `TempAudioCleanup` so tests can assert
    /// `delete(url:)` fires once per pipeline exit path.
    private final class CountingCleanup: TempAudioCleanup, @unchecked Sendable {
        private let lock = NSLock()
        private var _deletedURLs: [URL] = []
        private(set) var orphanScanCount = 0
        private(set) var cleanupAllCount = 0

        var deletedURLs: [URL] {
            lock.withLock { _deletedURLs }
        }

        func delete(url: URL) async {
            lock.withLock { _deletedURLs.append(url) }
        }

        func scanForOrphans() async {
            lock.withLock { orphanScanCount += 1 }
        }

        func cleanupAll() async {
            lock.withLock { cleanupAllCount += 1 }
        }
    }

    private struct Builder {
        var transcription = PreviewTranscriptionService()
        var diarization = FakeDiarizationService()
        var formatter = PreviewTranscriptFormatter()
        var store = PreviewTranscriptStore()
        var settings = PreviewSettingsStore()
        var exporter = PreviewObsidianExporter()
        var cleanup = CountingCleanup()

        func build() -> DefaultPipelineOrchestrator {
            DefaultPipelineOrchestrator(
                transcription: transcription,
                diarization: diarization,
                formatter: formatter,
                transcripts: store,
                settings: settings,
                exporter: exporter,
                cleanup: cleanup
            )
        }
    }

    private let dummyAudioURL = URL(fileURLWithPath: "/tmp/preview-recording.wav")

    // MARK: - Happy path

    /// Thread-safe progress collector — the orchestrator's closure is
    /// `@Sendable`, so a local `var [PipelineProgress]` can't be
    /// captured directly under Swift 6 strict concurrency.
    private final class ProgressBox: @unchecked Sendable {
        private let lock = NSLock()
        private var trail: [PipelineProgress] = []
        func append(_ p: PipelineProgress) { lock.withLock { trail.append(p) } }
        var snapshot: [PipelineProgress] { lock.withLock { trail } }
    }

    func test_happyPath_runsAllStages_returnsSavedID() async throws {
        let b = Builder()
        let orchestrator = b.build()
        let box = ProgressBox()
        let id = try await orchestrator.process(audioURL: dummyAudioURL) { progress in
            box.append(progress)
        }
        let stored = try await b.store.fetch(id: id)
        XCTAssertNotNil(stored)
        // First aggregate fraction should be ≤ last; monotonic
        let aggs = box.snapshot.map(\.aggregateFraction)
        for i in 1..<aggs.count {
            XCTAssertGreaterThanOrEqual(aggs[i], aggs[i - 1] - 0.0001, "Aggregate progress regressed at step \(i): \(aggs)")
        }
        XCTAssertEqual(aggs.last, 1.0, "Pipeline should end at 100%")
    }

    // MARK: - Cleanup (TEST-501 + TEST-502)

    func test_cleanup_firesOnSuccess() async throws {
        let b = Builder()
        let orchestrator = b.build()
        _ = try await orchestrator.process(audioURL: dummyAudioURL)
        // detached cleanup task — wait a beat
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(b.cleanup.deletedURLs, [dummyAudioURL])
    }

    func test_cleanup_firesOnTranscriptionFailure() async throws {
        let b = Builder()
        b.transcription.transcribeError = DeliberateError()
        let orchestrator = b.build()
        do {
            _ = try await orchestrator.process(audioURL: dummyAudioURL)
            XCTFail("Expected throw")
        } catch {
            // expected
        }
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(b.cleanup.deletedURLs, [dummyAudioURL], "Cleanup must still fire on error (TEST-501)")
    }

    func test_cleanup_firesOnCancel() async throws {
        let b = Builder()
        b.transcription.transcribeDelayNanoseconds = 200_000_000  // 200 ms
        let orchestrator = b.build()

        let task = Task {
            try await orchestrator.process(audioURL: dummyAudioURL)
        }
        try await Task.sleep(nanoseconds: 30_000_000)
        task.cancel()
        _ = try? await task.value

        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(b.cleanup.deletedURLs, [dummyAudioURL], "Cleanup must fire on cancel (TEST-502)")
    }

    // MARK: - Error short-circuit

    func test_transcriptionFailure_surfacesTranscriptionFailedError() async throws {
        let b = Builder()
        b.transcription.transcribeError = DeliberateError()
        let orchestrator = b.build()

        do {
            _ = try await orchestrator.process(audioURL: dummyAudioURL)
            XCTFail("Expected throw")
        } catch let error as OrchestrationError {
            if case .transcriptionFailed = error { /* expected */ } else { XCTFail("Wrong case: \(error)") }
        }
        let list = try await b.store.list(limit: 10, offset: 0)
        XCTAssertTrue(list.isEmpty, "Save must not run when transcribe fails")
    }

    func test_cancel_surfacesCancelledError() async throws {
        let b = Builder()
        b.transcription.transcribeDelayNanoseconds = 200_000_000
        let orchestrator = b.build()

        let task = Task {
            do {
                _ = try await orchestrator.process(audioURL: dummyAudioURL)
                XCTFail("Expected throw")
            } catch let error as OrchestrationError {
                if case .cancelled = error { /* expected */ } else { XCTFail("Wrong case: \(error)") }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        try await Task.sleep(nanoseconds: 30_000_000)
        task.cancel()
        await task.value
    }

    // MARK: - Auto-export

    func test_autoExportEnabled_chainsExportAfterSave() async throws {
        let b = Builder()
        try await b.settings.write(.autoExport, true)
        try await b.settings.write(.obsidianVaultPath, "/tmp/preview-vault")
        let orchestrator = b.build()
        _ = try await orchestrator.process(audioURL: dummyAudioURL)
        XCTAssertEqual(b.exporter.calls.count, 1)
        XCTAssertEqual(b.exporter.calls.first?.vaultPath, URL(fileURLWithPath: "/tmp/preview-vault"))
    }

    func test_exportFailure_doesNotInvalidateSave() async throws {
        let b = Builder()
        b.exporter.nextError = DeliberateError()
        try await b.settings.write(.autoExport, true)
        try await b.settings.write(.obsidianVaultPath, "/tmp/preview-vault")
        let orchestrator = b.build()
        let id = try await orchestrator.process(audioURL: dummyAudioURL)
        let stored = try await b.store.fetch(id: id)
        XCTAssertNotNil(stored)
        XCTAssertNil(stored?.exportedPath, "markExported must not run when export fails")
    }

    func test_autoExportDisabled_noExporterCall() async throws {
        let b = Builder()
        // Default autoExport = false
        let orchestrator = b.build()
        _ = try await orchestrator.process(audioURL: dummyAudioURL)
        XCTAssertTrue(b.exporter.calls.isEmpty)
    }
}
