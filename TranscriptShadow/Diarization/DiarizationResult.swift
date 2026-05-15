// @implements API-102, INT-102, FEA-003
import Foundation

/// Final diarization product handed back to callers.
///
/// Mirrors the EPIC-04a Phase B JSON envelope (schema version 1.0) emitted
/// by `sidecar/diarize.py`. The cross-language conformance fixture is
/// `sidecar/test_fixtures/golden-3spk.json` — this Codable type must
/// decode that file unchanged.
///
/// `segments` is the exclusive_speaker_diarization view (no overlapping
/// speech, preferred for transcription alignment in EPIC-05).
/// `overlappingSegments` is the speaker_diarization view (allowing
/// simultaneous speakers).
public struct DiarizationResult: Codable, Sendable, Equatable {
    public let version: String
    public let audio: AudioInfo
    public let model: ModelInfo
    public let speakers: [Speaker]
    public let segments: [SpeakerSegment]
    public let overlappingSegments: [SpeakerSegment]
    public let elapsedSeconds: TimeInterval
    public let warnings: [String]

    public init(
        version: String,
        audio: AudioInfo,
        model: ModelInfo,
        speakers: [Speaker],
        segments: [SpeakerSegment],
        overlappingSegments: [SpeakerSegment],
        elapsedSeconds: TimeInterval,
        warnings: [String] = []
    ) {
        self.version = version
        self.audio = audio
        self.model = model
        self.speakers = speakers
        self.segments = segments
        self.overlappingSegments = overlappingSegments
        self.elapsedSeconds = elapsedSeconds
        self.warnings = warnings
    }

    enum CodingKeys: String, CodingKey {
        case version
        case audio
        case model
        case speakers
        case segments
        case overlappingSegments = "overlapping_segments"
        case elapsedSeconds = "elapsed_seconds"
        case warnings
    }
}

public extension DiarizationResult {
    /// The schema version this Codable type was written for. The
    /// `PyannoteSidecarDiarizationService` rejects payloads whose
    /// `version` field doesn't match (Codex Gate 2 P2, 2026-05-09).
    static let supportedSchemaVersion = "1.0"

    /// The total speech time across all speakers (sum of `speakers[].totalSeconds`).
    /// Useful as a sanity check against `audio.durationSeconds`.
    var totalSpeechSeconds: TimeInterval {
        speakers.reduce(0) { $0 + $1.totalSeconds }
    }
}

/// The input audio file the sidecar processed.
public struct AudioInfo: Codable, Sendable, Equatable {
    public let path: String
    public let durationSeconds: TimeInterval

    public init(path: String, durationSeconds: TimeInterval) {
        self.path = path
        self.durationSeconds = durationSeconds
    }

    enum CodingKeys: String, CodingKey {
        case path
        case durationSeconds = "duration_seconds"
    }
}

/// The pyannote pipeline that produced the output.
public struct ModelInfo: Codable, Sendable, Equatable {
    public let name: String
    public let revision: String

    public init(name: String, revision: String) {
        self.name = name
        self.revision = revision
    }
}

/// Per-speaker aggregate. `id` is whatever pyannote emits — typically
/// `SPEAKER_00`, `SPEAKER_01`, etc. EPIC-07 may map these to user-supplied
/// names (e.g., "Alice").
public struct Speaker: Codable, Sendable, Equatable {
    public let id: String
    public let totalSeconds: TimeInterval

    public init(id: String, totalSeconds: TimeInterval) {
        self.id = id
        self.totalSeconds = totalSeconds
    }

    enum CodingKeys: String, CodingKey {
        case id
        case totalSeconds = "total_seconds"
    }
}

/// One contiguous diarized segment. `start` and `end` are seconds from the
/// beginning of the audio. `start < end` is invariant per the EPIC-04a
/// schema; consumers may assert it.
public struct SpeakerSegment: Codable, Sendable, Equatable {
    public let speaker: String
    public let start: TimeInterval
    public let end: TimeInterval

    public init(speaker: String, start: TimeInterval, end: TimeInterval) {
        self.speaker = speaker
        self.start = start
        self.end = end
    }

    public var duration: TimeInterval { end - start }
}
