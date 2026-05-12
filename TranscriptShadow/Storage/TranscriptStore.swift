// @implements DBT-001, DBT-002, DBT-003, FEA-006
import Foundation
import GRDB

/// Public persistence surface over DBT-001..003. Save consumes the
/// `FormattedTranscript` produced by EPIC-05 plus the user-facing
/// title and recording date; populates all three tables in a single
/// transaction.
///
/// Fetch / list / search return a `StoredTranscript` (full
/// reconstruction including turn rows) or `StoredTranscriptSummary`
/// (the lightweight metadata needed by EPIC-07's history list view).
public protocol TranscriptStore: Sendable {
    func save(
        formatted: FormattedTranscript,
        title: String,
        date: Date
    ) async throws -> StoredTranscript

    func fetch(id: UUID) async throws -> StoredTranscript?
    func list(limit: Int, offset: Int) async throws -> [StoredTranscriptSummary]
    func search(query: String, limit: Int) async throws -> [StoredTranscriptSummary]
    func markExported(id: UUID, to path: URL) async throws
    func delete(id: UUID) async throws
}

public struct StoredTranscript: Sendable, Equatable {
    public let id: UUID
    public let title: String
    public let date: Date
    public let durationSeconds: Int
    public let speakerCount: Int
    public let markdown: String
    public let model: String
    public let exportedPath: URL?
    public let createdAt: Date
    public let updatedAt: Date
    public let speakers: [SpeakerRecord]
    public let segments: [SegmentRecord]
}

public struct StoredTranscriptSummary: Sendable, Equatable {
    public let id: UUID
    public let title: String
    public let date: Date
    public let durationSeconds: Int
    public let speakerCount: Int
    public let exportedPath: URL?
}

public enum TranscriptStoreError: Error, Equatable {
    case notFound(UUID)
    case invalidUUID(String)
}

// MARK: - Default impl

public final class DefaultTranscriptStore: TranscriptStore, Sendable {
    private let database: AppDatabase
    private let clock: @Sendable () -> Date

    public init(database: AppDatabase, clock: @escaping @Sendable () -> Date = { Date() }) {
        self.database = database
        self.clock = clock
    }

    public func save(
        formatted: FormattedTranscript,
        title: String,
        date: Date
    ) async throws -> StoredTranscript {
        let now = clock()
        let transcriptID = UUID()
        let transcriptRecord = TranscriptRecord(
            id: transcriptID.uuidString,
            title: title,
            date: ISO8601.string(from: date),
            durationSeconds: formatted.metadata.durationSeconds,
            speakerCount: formatted.metadata.speakerCount,
            markdownContent: formatted.markdown,
            modelUsed: formatted.metadata.model.rawValue,
            exportedPath: nil,
            createdAt: ISO8601.string(from: now),
            updatedAt: ISO8601.string(from: now)
        )

        // canonical → SpeakerRecord (palette index by first appearance
        // in `turns` first, then any keys only present in `speakerMap`
        // appended in **sorted** order for determinism — dictionary
        // iteration is not order-stable across runs even in Swift 5.3+).
        var canonicalOrder: [String] = []
        var seen = Set<String>()
        for turn in formatted.turns {
            if seen.insert(turn.canonicalSpeaker).inserted {
                canonicalOrder.append(turn.canonicalSpeaker)
            }
        }
        for canonical in formatted.speakerMap.keys.sorted() where !seen.contains(canonical) {
            canonicalOrder.append(canonical)
            seen.insert(canonical)
        }

        var speakerIDByCanonical: [String: UUID] = [:]
        var speakingTimeByCanonical: [String: Double] = [:]
        for turn in formatted.turns {
            speakingTimeByCanonical[turn.canonicalSpeaker, default: 0] +=
                max(0, turn.endSeconds - turn.startSeconds)
        }

        var speakerRecords: [SpeakerRecord] = []
        for (index, canonical) in canonicalOrder.enumerated() {
            let speakerID = UUID()
            speakerIDByCanonical[canonical] = speakerID
            speakerRecords.append(SpeakerRecord(
                id: speakerID.uuidString,
                transcriptId: transcriptID.uuidString,
                speakerKey: canonical,
                displayName: formatted.speakerMap[canonical] ?? canonical,
                colorIndex: index,
                speakingTimeSeconds: speakingTimeByCanonical[canonical]
            ))
        }

        var segmentRecords: [SegmentRecord] = []
        for (index, turn) in formatted.turns.enumerated() {
            guard let speakerID = speakerIDByCanonical[turn.canonicalSpeaker] else { continue }
            segmentRecords.append(SegmentRecord(
                id: UUID().uuidString,
                transcriptId: transcriptID.uuidString,
                speakerId: speakerID.uuidString,
                startTime: turn.startSeconds,
                endTime: turn.endSeconds,
                text: turn.text,
                sequence: index
            ))
        }

        try await database.queue.write { db in
            try transcriptRecord.insert(db)
            for record in speakerRecords {
                try record.insert(db)
            }
            for record in segmentRecords {
                try record.insert(db)
            }
        }

        return StoredTranscript(
            id: transcriptID,
            title: title,
            date: date,
            durationSeconds: transcriptRecord.durationSeconds,
            speakerCount: transcriptRecord.speakerCount,
            markdown: transcriptRecord.markdownContent,
            model: transcriptRecord.modelUsed,
            exportedPath: nil,
            createdAt: now,
            updatedAt: now,
            speakers: speakerRecords,
            segments: segmentRecords
        )
    }

    public func fetch(id: UUID) async throws -> StoredTranscript? {
        try await database.queue.read { db in
            guard let record = try TranscriptRecord.fetchOne(db, key: id.uuidString) else {
                return nil
            }
            let speakers = try SpeakerRecord
                .filter(Column("transcript_id") == id.uuidString)
                .fetchAll(db)
            let segments = try SegmentRecord
                .filter(Column("transcript_id") == id.uuidString)
                .order(Column("sequence"))
                .fetchAll(db)
            return Self.makeStored(from: record, speakers: speakers, segments: segments)
        }
    }

    public func list(limit: Int, offset: Int) async throws -> [StoredTranscriptSummary] {
        try await database.queue.read { db in
            let records = try TranscriptRecord
                .order(Column("date").desc)
                .limit(limit, offset: offset)
                .fetchAll(db)
            return records.compactMap(Self.makeSummary(from:))
        }
    }

    public func search(query: String, limit: Int) async throws -> [StoredTranscriptSummary] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return try await database.queue.read { db in
            let sql = """
                SELECT t.* FROM transcripts t
                JOIN transcripts_fts fts ON fts.rowid = t.rowid
                WHERE transcripts_fts MATCH ?
                ORDER BY t.date DESC
                LIMIT ?
            """
            let records = try TranscriptRecord.fetchAll(
                db,
                sql: sql,
                arguments: [Self.escapeFTS(trimmed), limit]
            )
            return records.compactMap(Self.makeSummary(from:))
        }
    }

    public func markExported(id: UUID, to path: URL) async throws {
        let updatedAt = ISO8601.string(from: clock())
        try await database.queue.write { db in
            let affected = try db.execute(
                sql: """
                    UPDATE transcripts
                    SET exported_path = ?, updated_at = ?
                    WHERE id = ?
                """,
                arguments: [path.path, updatedAt, id.uuidString]
            )
            if affected == 0 {
                throw TranscriptStoreError.notFound(id)
            }
        }
    }

    public func delete(id: UUID) async throws {
        try await database.queue.write { db in
            let deleted = try TranscriptRecord.deleteOne(db, key: id.uuidString)
            if !deleted {
                throw TranscriptStoreError.notFound(id)
            }
        }
    }

    // MARK: - Helpers

    private static func makeStored(
        from record: TranscriptRecord,
        speakers: [SpeakerRecord],
        segments: [SegmentRecord]
    ) -> StoredTranscript? {
        guard
            let id = UUID(uuidString: record.id),
            let date = ISO8601.date(from: record.date),
            let createdAt = ISO8601.date(from: record.createdAt),
            let updatedAt = ISO8601.date(from: record.updatedAt)
        else {
            return nil
        }
        return StoredTranscript(
            id: id,
            title: record.title,
            date: date,
            durationSeconds: record.durationSeconds,
            speakerCount: record.speakerCount,
            markdown: record.markdownContent,
            model: record.modelUsed,
            exportedPath: record.exportedPath.map { URL(fileURLWithPath: $0) },
            createdAt: createdAt,
            updatedAt: updatedAt,
            speakers: speakers,
            segments: segments
        )
    }

    private static func makeSummary(from record: TranscriptRecord) -> StoredTranscriptSummary? {
        guard
            let id = UUID(uuidString: record.id),
            let date = ISO8601.date(from: record.date)
        else {
            return nil
        }
        return StoredTranscriptSummary(
            id: id,
            title: record.title,
            date: date,
            durationSeconds: record.durationSeconds,
            speakerCount: record.speakerCount,
            exportedPath: record.exportedPath.map { URL(fileURLWithPath: $0) }
        )
    }

    /// Quote a user-typed query so FTS5 treats it as a literal phrase
    /// (or sequence of OR'd tokens). Wraps in double quotes and
    /// doubles any inner quotes per FTS5's escape rule.
    private static func escapeFTS(_ raw: String) -> String {
        let escaped = raw.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

// MARK: - ISO8601 helper

/// Thread-safe ISO8601 conversion. `ISO8601DateFormatter` instances are
/// not safe to share across threads/queues — Foundation documents this
/// for `DateFormatter` and the ISO variant inherits the same constraint
/// in practice. Each call constructs a fresh formatter (cheap; the
/// instance has no resources beyond a few stored option bits) so GRDB's
/// concurrent `queue.read` callers cannot race on a shared state.
enum ISO8601 {
    private static func makeFormatter() -> ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }

    static func string(from date: Date) -> String {
        makeFormatter().string(from: date)
    }

    static func date(from string: String) -> Date? {
        makeFormatter().date(from: string)
    }
}
