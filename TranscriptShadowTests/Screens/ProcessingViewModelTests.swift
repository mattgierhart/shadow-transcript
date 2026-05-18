// @implements SCR-003, UJ-001, ARC-001
// Tests for the SCR-003 pipeline view-model. Verifies the happy path
// (every stage completes, store saves, onComplete fires), cancellation
// propagation, error short-circuit, and the autoExport branch.

import XCTest
@testable import TranscriptShadow

@MainActor
final class ProcessingViewModelTests: XCTestCase {
    private struct DeliberateError: Error, LocalizedError {
        let errorDescription: String? = "Deliberate failure"
    }

    private func makeEnv(
        transcription: PreviewTranscriptionService = PreviewTranscriptionService(),
        store: PreviewTranscriptStore = PreviewTranscriptStore(),
        exporter: PreviewObsidianExporter = PreviewObsidianExporter(),
        settings: PreviewSettingsStore = PreviewSettingsStore()
    ) -> (AppEnvironment, PreviewTranscriptionService, PreviewTranscriptStore, PreviewObsidianExporter, PreviewSettingsStore) {
        let env = AppEnvironment(
            audioCapture: PreviewAudioCaptureService(),
            transcription: transcription,
            diarization: FakeDiarizationService(),
            formatter: PreviewTranscriptFormatter(),
            transcripts: store,
            settings: settings,
            exporter: exporter
        )
        return (env, transcription, store, exporter, settings)
    }

    private let dummyAudioURL = URL(fileURLWithPath: "/tmp/preview-recording.wav")

    // MARK: - Happy path

    func test_pipelineHappyPath_advancesEveryStage_andSaves() async throws {
        let (env, _, store, exporter, _) = makeEnv()
        let vm = ProcessingViewModel(env: env)

        let exp = expectation(description: "pipeline complete")
        var savedID: UUID?
        vm.onComplete = { id in
            savedID = id
            exp.fulfill()
        }
        vm.start(audioURL: dummyAudioURL)
        await fulfillment(of: [exp], timeout: 5.0)

        XCTAssertNotNil(savedID)
        XCTAssertNil(vm.error)
        XCTAssertEqual(vm.stages.map(\.status), [.done, .done, .done])
        XCTAssertEqual(vm.stages.map(\.percent), [100, 100, 100])
        let saved = try await store.fetch(id: savedID!)
        XCTAssertNotNil(saved)
        XCTAssertTrue(exporter.calls.isEmpty, "autoExport off → no exporter call")
    }

    // MARK: - Cancel propagation

    func test_cancel_propagatesAndShortCircuitsPipeline() async throws {
        let transcription = PreviewTranscriptionService()
        transcription.transcribeDelayNanoseconds = 200_000_000  // 200 ms
        let (env, _, store, _, _) = makeEnv(transcription: transcription)
        let vm = ProcessingViewModel(env: env)

        var cancelled = false
        vm.onCancel = { cancelled = true }
        vm.start(audioURL: dummyAudioURL)
        // Cancel almost immediately while transcribe is sleeping
        try await Task.sleep(nanoseconds: 30_000_000)
        vm.cancel()
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertTrue(cancelled, "onCancel should fire")
        // No save happened
        let list = try await store.list(limit: 10, offset: 0)
        XCTAssertTrue(list.isEmpty, "Cancellation must short-circuit the save stage")
    }

    // MARK: - Failure modes

    func test_transcriptionFailure_doesNotSave_andSurfacesError() async throws {
        let transcription = PreviewTranscriptionService()
        transcription.transcribeError = DeliberateError()
        let (env, _, store, _, _) = makeEnv(transcription: transcription)
        let vm = ProcessingViewModel(env: env)

        vm.start(audioURL: dummyAudioURL)
        // Wait for the pipeline task to finish (it errors quickly).
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertNotNil(vm.error)
        // Phase-4 orchestrator wraps service errors in
        // OrchestrationError.transcriptionFailed before surfacing —
        // the VM shows the localizedDescription of that case.
        XCTAssertTrue(vm.error?.contains("Transcription failed") == true,
                      "Expected wrapped transcription error, got: \(vm.error ?? "nil")")
        let list = try await store.list(limit: 10, offset: 0)
        XCTAssertTrue(list.isEmpty, "Failed transcribe should not produce a saved row")
        // Transcribe stage marked error
        XCTAssertEqual(vm.stages.first(where: { $0.id == "transcribe" })?.status, .error)
    }

    // MARK: - Auto-export

    func test_autoExportEnabled_chainsExportAfterSave() async throws {
        let store = PreviewTranscriptStore()
        let exporter = PreviewObsidianExporter()
        let settings = PreviewSettingsStore()
        let (env, _, _, _, _) = makeEnv(store: store, exporter: exporter, settings: settings)

        try await settings.write(.autoExport, true)
        try await settings.write(.obsidianVaultPath, "/tmp/preview-vault")
        try await settings.write(.obsidianSubfolder, "Meetings")

        let vm = ProcessingViewModel(env: env)
        let exp = expectation(description: "pipeline complete")
        vm.onComplete = { _ in exp.fulfill() }

        vm.start(audioURL: dummyAudioURL)
        await fulfillment(of: [exp], timeout: 5.0)

        XCTAssertEqual(exporter.calls.count, 1)
        XCTAssertEqual(exporter.calls.first?.vaultPath, URL(fileURLWithPath: "/tmp/preview-vault"))
        XCTAssertEqual(exporter.calls.first?.subfolder, "Meetings")
        // markExported was called
        let list = try await store.list(limit: 10, offset: 0)
        XCTAssertEqual(list.first?.exportedPath, exporter.nextReturnURL)
    }

    func test_exportFailure_doesNotInvalidateSave() async throws {
        let store = PreviewTranscriptStore()
        let exporter = PreviewObsidianExporter()
        exporter.nextError = DeliberateError()
        let settings = PreviewSettingsStore()
        let (env, _, _, _, _) = makeEnv(store: store, exporter: exporter, settings: settings)

        try await settings.write(.autoExport, true)
        try await settings.write(.obsidianVaultPath, "/tmp/preview-vault")

        let vm = ProcessingViewModel(env: env)
        let exp = expectation(description: "pipeline complete despite export failure")
        var savedID: UUID?
        vm.onComplete = { id in
            savedID = id
            exp.fulfill()
        }
        vm.start(audioURL: dummyAudioURL)
        await fulfillment(of: [exp], timeout: 5.0)

        XCTAssertNotNil(savedID, "Save should succeed even when export fails")
        // The transcript is in the store
        let saved = try await store.fetch(id: savedID!)
        XCTAssertNotNil(saved)
        // exportedPath was never written (markExported is best-effort
        // and only fires on successful export)
        XCTAssertNil(saved?.exportedPath)
    }
}
