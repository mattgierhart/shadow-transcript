// @implements DBT-001, DBT-002, DBT-003, DBT-101, TECH-007
import Foundation
import GRDB

/// GRDB migration registry. One v1 migration creates DBT-001..003 +
/// DBT-101 + the FTS5 contentless-content virtual table over
/// `transcripts.markdown_content` plus the sync triggers.
///
/// New migrations: append `migrator.registerMigration("002_…") { db in … }`.
/// **Never** edit a registered migration — write a new one. GRDB tracks
/// applied names in `grdb_migrations` and fails the diff at startup.
public enum DatabaseMigrations {

    public static func migrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        register001(in: &migrator)
        return migrator
    }

    // MARK: - v1: initial schema

    private static func register001(in migrator: inout DatabaseMigrator) {
        migrator.registerMigration("001_initial_schema") { db in
            try createTranscripts(db)
            try createSpeakers(db)
            try createSegments(db)
            try createAppSettings(db)
            try createTranscriptsFTS(db)
        }
    }

    // DBT-001
    private static func createTranscripts(_ db: Database) throws {
        try db.create(table: "transcripts") { t in
            t.column("id", .text).primaryKey()
            t.column("title", .text).notNull()
            t.column("date", .text).notNull()                    // ISO8601
            t.column("duration_seconds", .integer).notNull()
            t.column("speaker_count", .integer).notNull()
            t.column("markdown_content", .text).notNull()
            t.column("model_used", .text).notNull()
            t.column("exported_path", .text)                     // optional
            t.column("created_at", .text).notNull()              // ISO8601
            t.column("updated_at", .text).notNull()              // ISO8601
        }
        try db.create(index: "idx_transcripts_date", on: "transcripts", columns: ["date"])
    }

    // DBT-002
    private static func createSpeakers(_ db: Database) throws {
        try db.create(table: "speakers") { t in
            t.column("id", .text).primaryKey()
            t.column("transcript_id", .text)
                .notNull()
                .references("transcripts", onDelete: .cascade)
            t.column("speaker_key", .text).notNull()             // SPEAKER_00
            t.column("display_name", .text).notNull()            // "Alice"
            t.column("color_index", .integer).notNull()
            t.column("speaking_time_seconds", .double)
            t.uniqueKey(["transcript_id", "speaker_key"])
        }
        try db.create(
            index: "idx_speakers_transcript",
            on: "speakers",
            columns: ["transcript_id"]
        )
    }

    // DBT-003
    private static func createSegments(_ db: Database) throws {
        try db.create(table: "segments") { t in
            t.column("id", .text).primaryKey()
            t.column("transcript_id", .text)
                .notNull()
                .references("transcripts", onDelete: .cascade)
            t.column("speaker_id", .text)
                .notNull()
                .references("speakers", onDelete: .cascade)
            t.column("start_time", .double).notNull()
            t.column("end_time", .double).notNull()
            t.column("text", .text).notNull()
            t.column("sequence", .integer).notNull()
        }
        try db.create(
            index: "idx_segments_transcript",
            on: "segments",
            columns: ["transcript_id"]
        )
        try db.create(
            index: "idx_segments_transcript_sequence",
            on: "segments",
            columns: ["transcript_id", "sequence"]
        )
    }

    // DBT-101
    private static func createAppSettings(_ db: Database) throws {
        try db.create(table: "app_settings") { t in
            t.column("key", .text).primaryKey()
            t.column("value", .text).notNull()                   // JSON-encoded
            t.column("updated_at", .text).notNull()              // ISO8601
        }
    }

    // FTS5 over transcripts.markdown_content. External-content variant
    // (`content='transcripts'` + `content_rowid='rowid'`) so we don't
    // store the text twice. Sync triggers keep the FTS index aligned
    // with INSERT/UPDATE/DELETE on the base table.
    private static func createTranscriptsFTS(_ db: Database) throws {
        try db.execute(sql: """
            CREATE VIRTUAL TABLE transcripts_fts USING fts5(
                markdown_content,
                content='transcripts',
                content_rowid='rowid',
                tokenize='porter unicode61'
            )
        """)

        try db.execute(sql: """
            CREATE TRIGGER transcripts_ai AFTER INSERT ON transcripts BEGIN
                INSERT INTO transcripts_fts (rowid, markdown_content)
                VALUES (new.rowid, new.markdown_content);
            END
        """)

        try db.execute(sql: """
            CREATE TRIGGER transcripts_ad AFTER DELETE ON transcripts BEGIN
                INSERT INTO transcripts_fts (transcripts_fts, rowid, markdown_content)
                VALUES ('delete', old.rowid, old.markdown_content);
            END
        """)

        try db.execute(sql: """
            CREATE TRIGGER transcripts_au AFTER UPDATE ON transcripts BEGIN
                INSERT INTO transcripts_fts (transcripts_fts, rowid, markdown_content)
                VALUES ('delete', old.rowid, old.markdown_content);
                INSERT INTO transcripts_fts (rowid, markdown_content)
                VALUES (new.rowid, new.markdown_content);
            END
        """)
    }
}
