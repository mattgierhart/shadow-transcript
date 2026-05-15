// @implements DBT-001
import Foundation
import GRDB

/// DBT-001 row. Codable + FetchableRecord + PersistableRecord = full
/// auto-derived CRUD via GRDB. `id` is a UUID stored as the lowercase
/// string form for FK joinability. Dates are ISO8601 strings (also for
/// readability when poking the DB with `sqlite3`).
public struct TranscriptRecord: Codable, FetchableRecord, PersistableRecord, Sendable, Equatable {
    public static let databaseTableName = "transcripts"

    public var id: String
    public var title: String
    public var date: String                  // ISO8601
    public var durationSeconds: Int
    public var speakerCount: Int
    public var markdownContent: String
    public var modelUsed: String
    public var exportedPath: String?
    public var createdAt: String             // ISO8601
    public var updatedAt: String             // ISO8601

    public init(
        id: String,
        title: String,
        date: String,
        durationSeconds: Int,
        speakerCount: Int,
        markdownContent: String,
        modelUsed: String,
        exportedPath: String?,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.durationSeconds = durationSeconds
        self.speakerCount = speakerCount
        self.markdownContent = markdownContent
        self.modelUsed = modelUsed
        self.exportedPath = exportedPath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case date
        case durationSeconds = "duration_seconds"
        case speakerCount = "speaker_count"
        case markdownContent = "markdown_content"
        case modelUsed = "model_used"
        case exportedPath = "exported_path"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
