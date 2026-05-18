// @implements SCR-004, UJ-002, API-201, DBT-002
// Tests for the transcript view-model: load + project + rename +
// collision + display-model regeneration.

import XCTest
@testable import TranscriptShadow

@MainActor
final class TranscriptViewModelTests: XCTestCase {
    /// Seeds a multi-speaker transcript so rename propagation has
    /// something interesting to verify.
    private func seedThreeSpeakerTranscript(in store: PreviewTranscriptStore) async throws -> StoredTranscript {
        let formatted = FormattedTranscript(
            markdown: "**Speaker 1** [00:00:00]:\nHello.\n\n**Speaker 2** [00:00:05]:\nHi.\n\n**Speaker 3** [00:00:10]:\nGreetings.\n",
            metadata: TranscriptMetadata(
                durationSeconds: 15,
                speakerCount: 3,
                language: "en",
                model: .baseEN,
                wordCount: 3,
                turnCount: 3
            ),
            speakerMap: ["SPEAKER_00": "Speaker 1", "SPEAKER_01": "Speaker 2", "SPEAKER_02": "Speaker 3"],
            warnings: [],
            turns: [
                TranscriptTurn(canonicalSpeaker: "SPEAKER_00", displayName: "Speaker 1", startSeconds: 0,  endSeconds: 4,  text: "Hello."),
                TranscriptTurn(canonicalSpeaker: "SPEAKER_01", displayName: "Speaker 2", startSeconds: 5,  endSeconds: 9,  text: "Hi."),
                TranscriptTurn(canonicalSpeaker: "SPEAKER_02", displayName: "Speaker 3", startSeconds: 10, endSeconds: 14, text: "Greetings."),
                TranscriptTurn(canonicalSpeaker: "SPEAKER_00", displayName: "Speaker 1", startSeconds: 15, endSeconds: 17, text: "Goodbye.")
            ]
        )
        return try await store.save(formatted: formatted, title: "Three Speakers", date: Date())
    }

    private func makeEnv(transcripts: PreviewTranscriptStore) -> AppEnvironment {
        AppEnvironment(
            audioCapture: PreviewAudioCaptureService(),
            transcription: PreviewTranscriptionService(),
            diarization: FakeDiarizationService(),
            formatter: PreviewTranscriptFormatter(),
            transcripts: transcripts,
            settings: PreviewSettingsStore(),
            exporter: PreviewObsidianExporter()
        )
    }

    // MARK: - Load

    func test_load_demoID_keepsMockDisplay() async {
        let env = AppEnvironment.preview()
        let vm = TranscriptViewModel(env: env)
        await vm.load(id: "t1")
        XCTAssertEqual(vm.displayModel.title, TranscriptDisplayModel.mock.title)
        XCTAssertNil(vm.transcriptID)
    }

    func test_load_uuidProjectedFromStore() async throws {
        let store = PreviewTranscriptStore()
        let stored = try await seedThreeSpeakerTranscript(in: store)
        let env = makeEnv(transcripts: store)

        let vm = TranscriptViewModel(env: env)
        await vm.load(id: stored.id)
        XCTAssertEqual(vm.transcriptID, stored.id)
        XCTAssertEqual(vm.displayModel.title, "Three Speakers")
        XCTAssertEqual(vm.displayModel.speakerCount, 3)
        XCTAssertEqual(vm.displayModel.speakers.count, 3)
        // Three actual turns + one repeat = 4 segments stored
        XCTAssertEqual(vm.displayModel.turns.count, 4)
    }

    // MARK: - Rename

    func test_renameSpeaker_propagatesAcrossAllTurns() async throws {
        let store = PreviewTranscriptStore()
        let stored = try await seedThreeSpeakerTranscript(in: store)
        let env = makeEnv(transcripts: store)
        let vm = TranscriptViewModel(env: env)
        await vm.load(id: stored.id)

        await vm.renameSpeaker(canonical: "SPEAKER_00", to: "Greg")
        XCTAssertNil(vm.renameError)
        // Speakers list updated
        let greg = vm.displayModel.speakers.first(where: { $0.canonicalKey == "SPEAKER_00" })
        XCTAssertEqual(greg?.name, "Greg")
        // Both turns referencing SPEAKER_00 should now show "Greg"
        let gregTurns = vm.displayModel.turns.filter { $0.speakerName == "Greg" }
        XCTAssertEqual(gregTurns.count, 2)
    }

    func test_renameSpeaker_persistsToStore() async throws {
        let store = PreviewTranscriptStore()
        let stored = try await seedThreeSpeakerTranscript(in: store)
        let env = makeEnv(transcripts: store)
        let vm = TranscriptViewModel(env: env)
        await vm.load(id: stored.id)

        await vm.renameSpeaker(canonical: "SPEAKER_01", to: "Priya")
        XCTAssertNil(vm.renameError)

        // Fetch again to confirm persistence
        let refetched = try await store.fetch(id: stored.id)
        let priya = refetched?.speakers.first(where: { $0.speakerKey == "SPEAKER_01" })
        XCTAssertEqual(priya?.displayName, "Priya")
    }

    func test_renameSpeaker_rejectsCollisionWithSiblingDisplayName() async throws {
        let store = PreviewTranscriptStore()
        let stored = try await seedThreeSpeakerTranscript(in: store)
        let env = makeEnv(transcripts: store)
        let vm = TranscriptViewModel(env: env)
        await vm.load(id: stored.id)

        // Rename SPEAKER_00 → "Lena Ortiz"
        await vm.renameSpeaker(canonical: "SPEAKER_00", to: "Lena Ortiz")
        XCTAssertNil(vm.renameError)

        // Now try to rename SPEAKER_01 → "Lena Ortiz" — should collide
        await vm.renameSpeaker(canonical: "SPEAKER_01", to: "Lena Ortiz")
        XCTAssertNotNil(vm.renameError)
        // SPEAKER_01 still has its old name
        let s1 = vm.displayModel.speakers.first(where: { $0.canonicalKey == "SPEAKER_01" })
        XCTAssertEqual(s1?.name, "Speaker 2")
    }

    func test_renameSpeaker_rejectsBlankName() async throws {
        let store = PreviewTranscriptStore()
        let stored = try await seedThreeSpeakerTranscript(in: store)
        let env = makeEnv(transcripts: store)
        let vm = TranscriptViewModel(env: env)
        await vm.load(id: stored.id)

        await vm.renameSpeaker(canonical: "SPEAKER_00", to: "   ")
        XCTAssertNotNil(vm.renameError)
        let s0 = vm.displayModel.speakers.first(where: { $0.canonicalKey == "SPEAKER_00" })
        XCTAssertEqual(s0?.name, "Speaker 1")
    }

    // MARK: - Export re-emits markdown (Codex Gate 5b P1 fix)

    func test_makeFormattedTranscript_reEmitsMarkdownFromCurrentDisplayNames() async throws {
        let store = PreviewTranscriptStore()
        let stored = try await seedThreeSpeakerTranscript(in: store)
        // Rename without re-saving the markdown body
        try await store.updateSpeakerDisplayName(
            transcriptID: stored.id,
            canonicalSpeaker: "SPEAKER_00",
            displayName: "Greg"
        )
        let refetched = try await store.fetch(id: stored.id)!
        let formatted = TranscriptViewModel.makeFormattedTranscript(from: refetched)
        XCTAssertTrue(formatted.markdown.contains("**Greg**"), "Renamed name should appear in exported markdown body")
        XCTAssertFalse(formatted.markdown.contains("**Speaker 1**"), "Old default name should be gone from the body")
        // Other speakers untouched
        XCTAssertTrue(formatted.markdown.contains("**Speaker 2**"))
        XCTAssertTrue(formatted.markdown.contains("**Speaker 3**"))
    }
}
