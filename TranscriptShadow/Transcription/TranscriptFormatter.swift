// @implements API-201, FEA-003, FEA-004, BR-301
import Foundation

/// Public transcript-formatting surface (API-201). Fuses a `Transcript`
/// (EPIC-03, word-timestamped) with a `DiarizationResult` (EPIC-04b,
/// speaker segments) into a `FormattedTranscript` containing
/// speaker-labeled markdown plus metadata.
///
/// Implementations are synchronous and stateless — alignment is pure CPU
/// work over Codable structs already in memory. EPIC-08's orchestrator
/// awaits the call inside its own task queue; this protocol does not
/// take an `AsyncTaskQueue` itself.
public protocol TranscriptFormatter: Sendable {
    /// - Parameters:
    ///   - transcription: WhisperKit output (API-101).
    ///   - diarization: Pyannote sidecar output (API-102).
    ///   - speakerNames: Optional override mapping canonical pyannote IDs
    ///     (e.g. `SPEAKER_00`) to display names (e.g. `"Alice"`). Empty by
    ///     default — defaults to `"Speaker N"` indexed by first appearance.
    /// - Returns: `FormattedTranscript` with body markdown, metadata, the
    ///   resolved display-name map, and any warnings (e.g. boundary
    ///   straddles, fallback paths taken).
    /// - Throws: `FormatterError.invalidSpeakerSegment` if a diarization
    ///   segment violates the `end > start` invariant (the pyannote sidecar
    ///   already enforces this; the throw exists for the EPIC-08
    ///   orchestrator's typed error path).
    func format(
        transcription: Transcript,
        diarization: DiarizationResult,
        speakerNames: [String: String]
    ) throws -> FormattedTranscript
}

public extension TranscriptFormatter {
    /// Convenience: no rename overrides — every speaker gets a default
    /// `"Speaker N"` display name.
    func format(
        transcription: Transcript,
        diarization: DiarizationResult
    ) throws -> FormattedTranscript {
        try format(transcription: transcription, diarization: diarization, speakerNames: [:])
    }
}

/// The fused output of API-201. `markdown` is body-only — the YAML
/// frontmatter and Obsidian-vault file write are EPIC-06's job
/// (`ObsidianExporter`). `speakerMap` keys are canonical pyannote IDs
/// (`SPEAKER_00`, plus `SPEAKER_UNKNOWN` if any words couldn't be
/// attributed); values are the resolved display names emitted in
/// markdown. `turns` exposes the per-turn structure used to render
/// `markdown` so downstream consumers (EPIC-06's persistence layer
/// populating DBT-002/DBT-003, EPIC-07's editable transcript view) can
/// reuse the alignment without re-deriving from `Transcript` +
/// `DiarizationResult`.
public struct FormattedTranscript: Codable, Sendable, Equatable {
    public let markdown: String
    public let metadata: TranscriptMetadata
    public let speakerMap: [String: String]
    public let warnings: [String]
    public let turns: [TranscriptTurn]

    public init(
        markdown: String,
        metadata: TranscriptMetadata,
        speakerMap: [String: String],
        warnings: [String],
        turns: [TranscriptTurn]
    ) {
        self.markdown = markdown
        self.metadata = metadata
        self.speakerMap = speakerMap
        self.warnings = warnings
        self.turns = turns
    }
}

/// One contiguous span of speech attributed to a single speaker.
/// `canonicalSpeaker` is the pyannote ID (`SPEAKER_00`,
/// `SPEAKER_UNKNOWN`, …) — the stable key suitable for DBT-002
/// `speakers.speaker_key`. `displayName` is the resolved label that
/// appears in the rendered markdown. `startSeconds` is the first
/// aligned token's start; `endSeconds` is the last aligned token's
/// end. `text` is the concatenated word text for the turn (single-space
/// joined, no leading/trailing whitespace).
public struct TranscriptTurn: Codable, Sendable, Equatable {
    public let canonicalSpeaker: String
    public let displayName: String
    public let startSeconds: TimeInterval
    public let endSeconds: TimeInterval
    public let text: String

    public init(
        canonicalSpeaker: String,
        displayName: String,
        startSeconds: TimeInterval,
        endSeconds: TimeInterval,
        text: String
    ) {
        self.canonicalSpeaker = canonicalSpeaker
        self.displayName = displayName
        self.startSeconds = startSeconds
        self.endSeconds = endSeconds
        self.text = text
    }
}

/// Numbers persisted alongside the markdown. Shapes align with DBT-001
/// columns so EPIC-06 can copy fields directly:
///   `durationSeconds` → `duration_seconds INTEGER`
///   `speakerCount`    → `speaker_count INTEGER`
///   `model.rawValue`  → `model_used TEXT`
public struct TranscriptMetadata: Codable, Sendable, Equatable {
    public let durationSeconds: Int
    public let speakerCount: Int
    public let language: String
    public let model: WhisperModel
    public let wordCount: Int
    public let turnCount: Int

    public init(
        durationSeconds: Int,
        speakerCount: Int,
        language: String,
        model: WhisperModel,
        wordCount: Int,
        turnCount: Int
    ) {
        self.durationSeconds = durationSeconds
        self.speakerCount = speakerCount
        self.language = language
        self.model = model
        self.wordCount = wordCount
        self.turnCount = turnCount
    }
}

public enum FormatterError: Error, Equatable {
    /// A diarization segment violated `end > start`. Reported with the
    /// offending pair so the caller can pinpoint it in the source JSON.
    case invalidSpeakerSegment(start: TimeInterval, end: TimeInterval)
}
