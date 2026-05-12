// @implements DBT-002
import Foundation
import GRDB

/// DBT-002 row. One row per (transcript, canonical pyannote ID) pair.
/// `speakerKey` is the canonical ID (`SPEAKER_00`, `SPEAKER_UNKNOWN`);
/// `displayName` is what the markdown rendering used and what EPIC-07
/// will edit. `colorIndex` is a stable palette slot for the UI.
public struct SpeakerRecord: Codable, FetchableRecord, PersistableRecord, Sendable, Equatable {
    public static let databaseTableName = "speakers"

    public var id: String
    public var transcriptId: String
    public var speakerKey: String
    public var displayName: String
    public var colorIndex: Int
    public var speakingTimeSeconds: Double?

    public init(
        id: String,
        transcriptId: String,
        speakerKey: String,
        displayName: String,
        colorIndex: Int,
        speakingTimeSeconds: Double?
    ) {
        self.id = id
        self.transcriptId = transcriptId
        self.speakerKey = speakerKey
        self.displayName = displayName
        self.colorIndex = colorIndex
        self.speakingTimeSeconds = speakingTimeSeconds
    }

    enum CodingKeys: String, CodingKey {
        case id
        case transcriptId = "transcript_id"
        case speakerKey = "speaker_key"
        case displayName = "display_name"
        case colorIndex = "color_index"
        case speakingTimeSeconds = "speaking_time_seconds"
    }
}
