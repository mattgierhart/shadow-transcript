// @implements DBT-003
import Foundation
import GRDB

/// DBT-003 row. One row per `TranscriptTurn` from EPIC-05's formatter.
/// `sequence` is the 0-indexed display order within a transcript;
/// queries that need turn-by-turn output order by it instead of by
/// `start_time` (which is otherwise sorted-ish but not guaranteed if a
/// future EPIC inserts overlap markers).
public struct SegmentRecord: Codable, FetchableRecord, PersistableRecord, Sendable, Equatable {
    public static let databaseTableName = "segments"

    public var id: String
    public var transcriptId: String
    public var speakerId: String
    public var startTime: Double
    public var endTime: Double
    public var text: String
    public var sequence: Int

    public init(
        id: String,
        transcriptId: String,
        speakerId: String,
        startTime: Double,
        endTime: Double,
        text: String,
        sequence: Int
    ) {
        self.id = id
        self.transcriptId = transcriptId
        self.speakerId = speakerId
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
        self.sequence = sequence
    }

    enum CodingKeys: String, CodingKey {
        case id
        case transcriptId = "transcript_id"
        case speakerId = "speaker_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case text
        case sequence
    }
}
