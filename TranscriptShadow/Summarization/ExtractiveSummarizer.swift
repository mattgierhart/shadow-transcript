// @implements API-401, FEA-007, BR-104
// Dependency-free, deterministic fallback summarizer. Used when Apple's
// on-device Foundation Models framework isn't available (pre-macOS 26, no
// Apple Intelligence, or a generation failure). Pure CPU work over the
// already-aligned `turns` — no model, no network, BR-104 trivially satisfied.
//
// This is intentionally simple extractive logic, NOT an LLM:
//   • overview     → speaker/turn counts + the opening sentence(s)
//   • key points   → the longest sentences (proxy for information density),
//                     re-sorted into transcript order for readability
//   • action items → sentences containing imperative / commitment cues
//
// It guarantees the FEA-007 surface is never empty even on machines that
// can't run the LLM, and doubles as the deterministic test oracle.

import Foundation

public struct ExtractiveSummarizer: SummarizationService, Sendable {
    public let maxKeyPoints: Int
    public let maxActionItems: Int

    public init(maxKeyPoints: Int = 5, maxActionItems: Int = 8) {
        self.maxKeyPoints = maxKeyPoints
        self.maxActionItems = maxActionItems
    }

    public func summarize(transcript: FormattedTranscript) async throws -> MeetingSummary {
        let sentences = Self.sentences(from: transcript.turns)
        guard !sentences.isEmpty else { throw SummarizationError.emptyTranscript }

        let overview = Self.makeOverview(
            speakerCount: transcript.metadata.speakerCount,
            turnCount: transcript.metadata.turnCount,
            sentences: sentences
        )
        let keyPoints = Self.topSentencesInOrder(sentences, limit: maxKeyPoints)
        let actionItems = Self.actionItems(from: sentences, limit: maxActionItems)

        return MeetingSummary(
            overview: overview,
            keyPoints: keyPoints,
            actionItems: actionItems,
            generator: "Extractive (on-device)"
        )
    }

    // MARK: - Sentence extraction

    /// Flatten every turn's text into trimmed, de-duplicated sentences.
    /// Splits on `.`, `!`, `?` followed by whitespace/end. Keeps sentences
    /// of ≥ 4 words so filler ("Yeah.", "Right.") doesn't dominate.
    static func sentences(from turns: [TranscriptTurn]) -> [String] {
        var result: [String] = []
        var seen = Set<String>()
        for turn in turns {
            for raw in splitSentences(turn.text) {
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                guard wordCount(trimmed) >= 4 else { continue }
                let key = trimmed.lowercased()
                if seen.insert(key).inserted {
                    result.append(trimmed)
                }
            }
        }
        return result
    }

    private static func splitSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        var current = ""
        for ch in text {
            current.append(ch)
            if ch == "." || ch == "!" || ch == "?" {
                sentences.append(current)
                current = ""
            }
        }
        if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sentences.append(current)
        }
        return sentences
    }

    private static func wordCount(_ text: String) -> Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }

    // MARK: - Overview

    private static func makeOverview(
        speakerCount: Int,
        turnCount: Int,
        sentences: [String]
    ) -> String {
        let speakerWord = speakerCount == 1 ? "speaker" : "speakers"
        let prefix = "Discussion between \(speakerCount) \(speakerWord) across \(turnCount) turns."
        // Opening 1-2 sentences give the reader the meeting's entry point.
        let opener = sentences.prefix(2).joined(separator: " ")
        return opener.isEmpty ? prefix : "\(prefix) \(opener)"
    }

    // MARK: - Key points

    /// Pick the `limit` longest sentences (information-density proxy), then
    /// restore transcript order so the bullets read top-to-bottom.
    static func topSentencesInOrder(_ sentences: [String], limit: Int) -> [String] {
        guard limit > 0, !sentences.isEmpty else { return [] }
        let indexed = sentences.enumerated().map { ($0.offset, $0.element) }
        // Stable selection: sort by word count desc, tie-break by original
        // order asc so the result is deterministic across runs.
        let chosen = indexed
            .sorted { lhs, rhs in
                let lw = wordCount(lhs.1), rw = wordCount(rhs.1)
                return lw == rw ? lhs.0 < rhs.0 : lw > rw
            }
            .prefix(limit)
        return chosen
            .sorted { $0.0 < $1.0 }
            .map { cleanBullet($0.1) }
    }

    // MARK: - Action items

    private static let actionCues: [String] = [
        "i'll ", "we'll ", "you'll ", "i will ", "we will ", "we need to ",
        "i need to ", "you need to ", "let's ", "let us ", "action item",
        "follow up", "follow-up", "todo", "to-do", "next step", "by tomorrow",
        "by next ", "by end of", "by eod", "assign", "take care of ",
        "make sure ", "send the ", "send out", "schedule a", "schedule the",
        "set up a", "set up the", "circle back", "own this", "owns this"
    ]

    static func actionItems(from sentences: [String], limit: Int) -> [String] {
        guard limit > 0 else { return [] }
        var items: [String] = []
        for sentence in sentences {
            let lower = sentence.lowercased()
            if actionCues.contains(where: { lower.contains($0) }) {
                items.append(cleanBullet(sentence))
                if items.count >= limit { break }
            }
        }
        return items
    }

    // MARK: - Helpers

    /// Trim and strip a single trailing sentence terminator for tidy bullets.
    private static func cleanBullet(_ sentence: String) -> String {
        var s = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        if let last = s.last, last == "." || last == "!" || last == "?" {
            s.removeLast()
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
