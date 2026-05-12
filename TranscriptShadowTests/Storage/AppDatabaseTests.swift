// @implements DBT-001, DBT-002, DBT-003, DBT-101, TECH-007
import XCTest
import GRDB
@testable import TranscriptShadow

final class AppDatabaseTests: XCTestCase {

    func test_migrate_createsAllExpectedTables() throws {
        let db = try AppDatabase.openInMemory()
        try db.migrate()

        let expected: Set<String> = [
            "transcripts",
            "speakers",
            "segments",
            "app_settings",
            "transcripts_fts",
        ]
        try db.queue.read { conn in
            for table in expected {
                XCTAssertTrue(
                    try conn.tableExists(table),
                    "Expected table \(table) to exist after migration"
                )
            }
        }
    }

    func test_migrate_isIdempotent() throws {
        let db = try AppDatabase.openInMemory()
        try db.migrate()
        XCTAssertNoThrow(try db.migrate(), "second migrate() must be a no-op")
    }

    func test_foreignKeys_areEnabledOnConnection() throws {
        let db = try AppDatabase.openInMemory()
        try db.migrate()
        let fkOn = try db.queue.read { conn -> Bool in
            let row = try Row.fetchOne(conn, sql: "PRAGMA foreign_keys")
            return (row?["foreign_keys"] as Int? ?? 0) == 1
        }
        XCTAssertTrue(fkOn, "Foreign keys must be ON to honor DBT-002/003 ON DELETE CASCADE")
    }

    func test_cascadeDelete_removesSpeakersAndSegments_whenTranscriptDeleted() throws {
        let db = try AppDatabase.openInMemory()
        try db.migrate()
        let transcriptID = UUID().uuidString
        let speakerID = UUID().uuidString
        try db.queue.write { conn in
            try TranscriptRecord(
                id: transcriptID,
                title: "x",
                date: ISO8601.string(from: Date()),
                durationSeconds: 0,
                speakerCount: 1,
                markdownContent: "",
                modelUsed: "openai_whisper-base.en",
                exportedPath: nil,
                createdAt: ISO8601.string(from: Date()),
                updatedAt: ISO8601.string(from: Date())
            ).insert(conn)
            try SpeakerRecord(
                id: speakerID,
                transcriptId: transcriptID,
                speakerKey: "SPEAKER_00",
                displayName: "Alice",
                colorIndex: 0,
                speakingTimeSeconds: 1.0
            ).insert(conn)
            try SegmentRecord(
                id: UUID().uuidString,
                transcriptId: transcriptID,
                speakerId: speakerID,
                startTime: 0,
                endTime: 1,
                text: "hi",
                sequence: 0
            ).insert(conn)
        }

        try db.queue.write { conn in
            _ = try TranscriptRecord.deleteOne(conn, key: transcriptID)
        }

        try db.queue.read { conn in
            XCTAssertEqual(try SpeakerRecord.fetchCount(conn), 0)
            XCTAssertEqual(try SegmentRecord.fetchCount(conn), 0)
        }
    }
}
