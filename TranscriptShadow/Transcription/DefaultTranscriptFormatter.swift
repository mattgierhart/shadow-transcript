// @implements API-201, FEA-003, FEA-004, BR-301
import Foundation

/// Default `TranscriptFormatter` (API-201). Stateless `struct` —
/// `format(...)` is synchronous and deterministic.
///
/// Pipeline:
///   1. `WordSpeakerAligner.align` → `AlignmentResult` (tokens + first-
///      appearance canonical order + warnings).
///   2. Build `speakerMap`: 1-indexed `Speaker N` display names per
///      canonical ID, overridden by caller-supplied `speakerNames`.
///   3. Group consecutive tokens by canonical speaker into turns.
///   4. Emit markdown — `**Display Name** [HH:MM:SS]:\n<text>\n\n…`
///      (body only; YAML frontmatter is EPIC-06's job).
public struct DefaultTranscriptFormatter: TranscriptFormatter, Sendable {
    /// Sentinel canonical ID used when alignment can't attribute a word.
    /// Surfaced in the output as `"Speaker ?"` unless the caller maps it
    /// to something else via `speakerNames`.
    static let unknownDisplayName = "Speaker ?"

    /// Maximum silence (seconds) between two consecutive same-speaker
    /// tokens before turn grouping treats them as separate turns. Without
    /// this split, a 5-minute monologue interrupted by long pauses would
    /// persist as one DBT-003 segment whose
    /// `endSeconds - startSeconds` covers non-speech time and breaks
    /// downstream UI scrubbing (Codex Gate P1 #4, 2026-05-15).
    public let turnSplitGapSeconds: TimeInterval

    public init(turnSplitGapSeconds: TimeInterval = 2.0) {
        self.turnSplitGapSeconds = turnSplitGapSeconds
    }

    public func format(
        transcription: Transcript,
        diarization: DiarizationResult,
        speakerNames: [String: String]
    ) throws -> FormattedTranscript {
        let aligner = WordSpeakerAligner()
        let alignment = try aligner.align(
            transcription: transcription,
            diarization: diarization
        )

        let speakerMap = buildSpeakerMap(
            canonicalOrder: alignment.canonicalOrder,
            overrides: speakerNames
        )

        let turns = groupIntoTurns(tokens: alignment.tokens, speakerMap: speakerMap)
        let markdown = renderMarkdown(turns: turns)

        let metadata = TranscriptMetadata(
            durationSeconds: Int(transcription.duration.rounded()),
            speakerCount: speakerMap.count,
            language: transcription.language,
            model: transcription.model,
            wordCount: alignment.tokens.count,
            turnCount: turns.count
        )

        let combinedWarnings = diarization.warnings + alignment.warnings

        return FormattedTranscript(
            markdown: markdown,
            metadata: metadata,
            speakerMap: speakerMap,
            warnings: combinedWarnings,
            turns: turns
        )
    }

    // MARK: - Speaker map

    private func buildSpeakerMap(
        canonicalOrder: [String],
        overrides: [String: String]
    ) -> [String: String] {
        var map: [String: String] = [:]
        var displayIndex = 1
        for canonical in canonicalOrder {
            if canonical == WordSpeakerAligner.unknownSpeakerID {
                map[canonical] = overrides[canonical] ?? Self.unknownDisplayName
            } else {
                map[canonical] = overrides[canonical] ?? "Speaker \(displayIndex)"
                displayIndex += 1
            }
        }
        return map
    }

    // MARK: - Turn grouping

    private func groupIntoTurns(
        tokens: [AlignedToken],
        speakerMap: [String: String]
    ) -> [TranscriptTurn] {
        guard !tokens.isEmpty else { return [] }
        var turns: [TranscriptTurn] = []
        var currentSpeaker = tokens[0].canonicalSpeaker
        var currentStart = tokens[0].start
        var currentEnd = tokens[0].end
        var currentWords: [String] = [tokens[0].text]

        for token in tokens.dropFirst() {
            let gap = token.start - currentEnd
            let sameSpeaker = token.canonicalSpeaker == currentSpeaker
            if sameSpeaker && gap <= turnSplitGapSeconds {
                currentWords.append(token.text)
                currentEnd = token.end
            } else {
                turns.append(makeTurn(
                    canonicalSpeaker: currentSpeaker,
                    startSeconds: currentStart,
                    endSeconds: currentEnd,
                    words: currentWords,
                    speakerMap: speakerMap
                ))
                currentSpeaker = token.canonicalSpeaker
                currentStart = token.start
                currentEnd = token.end
                currentWords = [token.text]
            }
        }
        turns.append(makeTurn(
            canonicalSpeaker: currentSpeaker,
            startSeconds: currentStart,
            endSeconds: currentEnd,
            words: currentWords,
            speakerMap: speakerMap
        ))
        return turns
    }

    private func makeTurn(
        canonicalSpeaker: String,
        startSeconds: TimeInterval,
        endSeconds: TimeInterval,
        words: [String],
        speakerMap: [String: String]
    ) -> TranscriptTurn {
        TranscriptTurn(
            canonicalSpeaker: canonicalSpeaker,
            displayName: speakerMap[canonicalSpeaker] ?? canonicalSpeaker,
            startSeconds: startSeconds,
            endSeconds: endSeconds,
            text: joined(words)
        )
    }

    private func joined(_ words: [String]) -> String {
        words
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    // MARK: - Markdown rendering

    private func renderMarkdown(turns: [TranscriptTurn]) -> String {
        turns.map { turn in
            let timestamp = formatTimestamp(turn.startSeconds)
            return "**\(turn.displayName)** [\(timestamp)]:\n\(turn.text)"
        }
        .joined(separator: "\n\n")
    }

    private func formatTimestamp(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}
