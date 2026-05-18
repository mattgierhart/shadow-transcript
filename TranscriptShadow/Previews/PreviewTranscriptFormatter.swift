// @implements API-201
// In-memory `TranscriptFormatter` used for SwiftUI previews + view-model
// unit tests. Synchronous; returns a baked `FormattedTranscript`.

import Foundation

public struct PreviewTranscriptFormatter: TranscriptFormatter, Sendable {
    /// What `format(...)` returns. Defaults to a minimal one-turn document.
    public var nextResult: FormattedTranscript

    public init(nextResult: FormattedTranscript = .preview) {
        self.nextResult = nextResult
    }

    public func format(
        transcription: Transcript,
        diarization: DiarizationResult,
        speakerNames: [String: String]
    ) throws -> FormattedTranscript {
        nextResult
    }
}

public extension FormattedTranscript {
    /// Tiny canned `FormattedTranscript` for previews + tests.
    static let preview = FormattedTranscript(
        markdown: "**Speaker 1** [00:00:00]:\nPreview transcript text.\n",
        metadata: TranscriptMetadata(
            durationSeconds: 5,
            speakerCount: 1,
            language: "en",
            model: .baseEN,
            wordCount: 3,
            turnCount: 1
        ),
        speakerMap: ["SPEAKER_00": "Speaker 1"],
        warnings: [],
        turns: [
            TranscriptTurn(
                canonicalSpeaker: "SPEAKER_00",
                displayName: "Speaker 1",
                startSeconds: 0,
                endSeconds: 5,
                text: "Preview transcript text."
            )
        ]
    )
}
