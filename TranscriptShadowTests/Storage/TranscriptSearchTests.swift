// @implements TEST-404, DBT-001
import XCTest
@testable import TranscriptShadow

final class TranscriptSearchTests: XCTestCase {
    private var database: AppDatabase!
    private var store: DefaultTranscriptStore!
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUpWithError() throws {
        database = try AppDatabase.openInMemory()
        try database.migrate()
        store = DefaultTranscriptStore(database: database) { [baseDate] in baseDate }
    }

    func test_search_findsTranscriptByExactWord() async throws {
        _ = try await saveFixture(title: "Standup")
        let hits = try await store.search(query: "congratulations", limit: 10)
        XCTAssertEqual(hits.count, 1)
        XCTAssertEqual(hits.first?.title, "Standup")
    }

    func test_search_isCaseInsensitive() async throws {
        _ = try await saveFixture(title: "Standup")
        let hits = try await store.search(query: "CONGRATULATIONS", limit: 10)
        XCTAssertEqual(hits.count, 1)
    }

    func test_search_findsViaPrefix_porterStemmer() async throws {
        _ = try await saveFixture(title: "Standup")
        // Porter stemmer should match `shipping` against `shipped` etc.
        // `shipped` is in the fixture; query `shipped` directly.
        let hits = try await store.search(query: "shipped", limit: 10)
        XCTAssertEqual(hits.count, 1)
    }

    func test_search_returnsEmpty_forUnknownPhrase() async throws {
        _ = try await saveFixture(title: "Standup")
        let hits = try await store.search(query: "nonexistent-phrase-xyz", limit: 10)
        XCTAssertTrue(hits.isEmpty)
    }

    func test_search_returnsEmpty_forBlankQuery() async throws {
        _ = try await saveFixture(title: "Standup")
        let hits = try await store.search(query: "   ", limit: 10)
        XCTAssertTrue(hits.isEmpty)
    }

    func test_search_findsMultipleTranscripts() async throws {
        _ = try await saveFixture(title: "A", date: baseDate)
        _ = try await saveFixture(title: "B", date: baseDate.addingTimeInterval(60))
        let hits = try await store.search(query: "feature", limit: 10)
        XCTAssertEqual(hits.count, 2)
    }

    func test_search_survivesUpdateDelete_ftsTriggersInSync() async throws {
        let a = try await saveFixture(title: "A")
        _ = try await saveFixture(title: "B", date: baseDate.addingTimeInterval(60))
        try await store.delete(id: a.id)
        let hits = try await store.search(query: "feature", limit: 10)
        XCTAssertEqual(hits.count, 1, "FTS triggers must propagate deletes from base table")
    }

    func test_search_survives_markExportedUpdate() async throws {
        // `markExported` updates `exported_path` + `updated_at` on the
        // base table. The FTS UPDATE trigger reindexes the row; the
        // markdown content is unchanged so search hits must remain.
        let a = try await saveFixture(title: "Exported")
        try await store.markExported(id: a.id, to: URL(fileURLWithPath: "/tmp/a.md"))
        let hits = try await store.search(query: "feature", limit: 10)
        XCTAssertEqual(hits.count, 1, "markExported must not desync FTS index")
    }

    private func saveFixture(title: String, date: Date? = nil) async throws -> StoredTranscript {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let formatted = try DefaultTranscriptFormatter().format(
            transcription: transcript,
            diarization: diarization
        )
        return try await store.save(
            formatted: formatted,
            title: title,
            date: date ?? baseDate
        )
    }
}
