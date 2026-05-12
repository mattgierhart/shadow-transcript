// @implements TEST-403, DBT-001, DBT-002, DBT-003
import XCTest
@testable import TranscriptShadow

final class TranscriptStoreTests: XCTestCase {
    private var database: AppDatabase!
    private var store: DefaultTranscriptStore!
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUpWithError() throws {
        database = try AppDatabase.openInMemory()
        try database.migrate()
        store = DefaultTranscriptStore(database: database) { [fixedDate] in fixedDate }
    }

    override func tearDown() {
        store = nil
        database = nil
    }

    // MARK: - TEST-403: persistence

    func test_save_persistsTranscriptSpeakersAndSegments() async throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let formatted = try DefaultTranscriptFormatter().format(
            transcription: transcript,
            diarization: diarization
        )

        let stored = try await store.save(
            formatted: formatted,
            title: "Standup",
            date: fixedDate
        )

        XCTAssertEqual(stored.title, "Standup")
        XCTAssertEqual(stored.speakerCount, 3)
        XCTAssertEqual(stored.speakers.count, 3)
        XCTAssertEqual(stored.segments.count, formatted.turns.count)
        XCTAssertEqual(stored.markdown, formatted.markdown)
        XCTAssertEqual(stored.model, "openai_whisper-base.en")
    }

    func test_save_preservesTurnOrderViaSequence() async throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let formatted = try DefaultTranscriptFormatter().format(
            transcription: transcript,
            diarization: diarization
        )
        let stored = try await store.save(formatted: formatted, title: "x", date: fixedDate)
        XCTAssertEqual(stored.segments.map(\.sequence), Array(0..<formatted.turns.count))
        XCTAssertEqual(stored.segments.map(\.text), formatted.turns.map(\.text))
    }

    func test_save_assignsStableSpeakerColorIndices_byFirstAppearance() async throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let formatted = try DefaultTranscriptFormatter().format(
            transcription: transcript,
            diarization: diarization
        )
        let stored = try await store.save(formatted: formatted, title: "x", date: fixedDate)
        let bySpeakerKey = Dictionary(uniqueKeysWithValues:
            stored.speakers.map { ($0.speakerKey, $0.colorIndex) }
        )
        XCTAssertEqual(bySpeakerKey["SPEAKER_00"], 0)
        XCTAssertEqual(bySpeakerKey["SPEAKER_01"], 1)
        XCTAssertEqual(bySpeakerKey["SPEAKER_02"], 2)
    }

    func test_save_recordsSpeakingTimePerSpeaker() async throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let formatted = try DefaultTranscriptFormatter().format(
            transcription: transcript,
            diarization: diarization
        )
        let stored = try await store.save(formatted: formatted, title: "x", date: fixedDate)
        for speaker in stored.speakers {
            let total = stored.segments
                .filter { $0.speakerId == speaker.id }
                .reduce(0.0) { $0 + ($1.endTime - $1.startTime) }
            XCTAssertEqual(speaker.speakingTimeSeconds ?? -1, total, accuracy: 1e-6)
        }
    }

    // MARK: - Fetch / list / mark exported / delete

    func test_fetch_returnsSavedTranscript() async throws {
        let stored = try await saveFixtureTranscript(title: "Standup")
        let fetched = try await store.fetch(id: stored.id)
        XCTAssertEqual(fetched?.id, stored.id)
        XCTAssertEqual(fetched?.markdown, stored.markdown)
        XCTAssertEqual(fetched?.speakers.count, stored.speakers.count)
        XCTAssertEqual(fetched?.segments.count, stored.segments.count)
    }

    func test_fetch_returnsNil_forMissingID() async throws {
        let fetched = try await store.fetch(id: UUID())
        XCTAssertNil(fetched)
    }

    func test_list_returnsSummariesInDescendingDateOrder() async throws {
        let older = try await saveFixtureTranscript(title: "Older", date: fixedDate)
        let newer = try await saveFixtureTranscript(
            title: "Newer",
            date: fixedDate.addingTimeInterval(86_400)
        )
        let summaries = try await store.list(limit: 10, offset: 0)
        XCTAssertEqual(summaries.map(\.id), [newer.id, older.id])
    }

    func test_markExported_updatesExportedPath() async throws {
        let stored = try await saveFixtureTranscript(title: "Exporting")
        let path = URL(fileURLWithPath: "/tmp/exported.md")
        try await store.markExported(id: stored.id, to: path)
        let fetched = try await store.fetch(id: stored.id)
        XCTAssertEqual(fetched?.exportedPath, path)
    }

    func test_markExported_throwsNotFound_whenIDMissing() async throws {
        do {
            try await store.markExported(id: UUID(), to: URL(fileURLWithPath: "/tmp/x.md"))
            XCTFail("expected throw")
        } catch TranscriptStoreError.notFound {
            // pass
        }
    }

    func test_delete_removesRowAndCascadesSpeakersSegments() async throws {
        let stored = try await saveFixtureTranscript(title: "Deletable")
        try await store.delete(id: stored.id)
        let fetched = try await store.fetch(id: stored.id)
        XCTAssertNil(fetched)
        // CASCADE verification: counts should be 0 in the DB
        try database.queue.read { conn in
            XCTAssertEqual(try SpeakerRecord.fetchCount(conn), 0)
            XCTAssertEqual(try SegmentRecord.fetchCount(conn), 0)
        }
    }

    // MARK: - Helpers

    private func saveFixtureTranscript(
        title: String,
        date: Date? = nil
    ) async throws -> StoredTranscript {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let formatted = try DefaultTranscriptFormatter().format(
            transcription: transcript,
            diarization: diarization
        )
        return try await store.save(
            formatted: formatted,
            title: title,
            date: date ?? fixedDate
        )
    }
}
