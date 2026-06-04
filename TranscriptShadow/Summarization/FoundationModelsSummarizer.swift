// @implements API-401, FEA-007, BR-104, TECH-008
// On-device LLM summarizer backed by Apple's Foundation Models framework
// (Apple Intelligence, macOS 26+). Entirely on-device — no network, no
// account — so BR-104/BR-101 hold.
//
// This whole file is compiled only when the SDK provides FoundationModels
// (macOS 26 SDK / Xcode 26). On the macOS-15 SDK used by the current CI
// runner, `canImport(FoundationModels)` is false and this file is empty,
// so the build falls back to `ExtractiveSummarizer`. The Foundation Models
// API surface is young; if it shifts, only this file needs to change.

#if canImport(FoundationModels)
import Foundation
import FoundationModels

@available(macOS 26.0, *)
public struct FoundationModelsSummarizer: SummarizationService, Sendable {
    /// Cap the transcript text handed to the model so a very long meeting
    /// stays within a comfortable context budget. Turns past this are
    /// dropped from the prompt (the extractive fallback covers the rest if
    /// generation fails). Characters, not tokens — deliberately conservative.
    public let maxPromptCharacters: Int

    public init(maxPromptCharacters: Int = 12_000) {
        self.maxPromptCharacters = maxPromptCharacters
    }

    public func summarize(transcript: FormattedTranscript) async throws -> MeetingSummary {
        guard !transcript.turns.isEmpty else { throw SummarizationError.emptyTranscript }

        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            throw SummarizationError.modelUnavailable("Apple Intelligence model not available")
        }

        let body = Self.transcriptText(transcript.turns, limit: maxPromptCharacters)
        let session = LanguageModelSession(instructions: Self.instructions)

        let content: String
        do {
            let response = try await session.respond(to: Self.prompt(for: body))
            content = response.content
        } catch {
            throw SummarizationError.generationFailed("\(error)")
        }

        let summary = Self.parse(content)
        guard !summary.isEmpty else {
            throw SummarizationError.generationFailed("empty model output")
        }
        return summary
    }

    // MARK: - Prompt

    static let instructions = """
    You are a meeting-notes assistant. You summarize a speaker-labeled \
    transcript into concise, factual notes. Never invent details that are \
    not in the transcript. Output ONLY the three sections requested, using \
    the exact headers given.
    """

    static func prompt(for body: String) -> String {
        """
        Summarize the following meeting transcript. Respond with exactly \
        these three sections and nothing else:

        OVERVIEW:
        <2-3 sentence plain-text overview>

        KEY POINTS:
        - <key discussion point>
        - <key discussion point>

        ACTION ITEMS:
        - <action item or follow-up, or "None" if there are none>

        Transcript:
        \(body)
        """
    }

    static func transcriptText(_ turns: [TranscriptTurn], limit: Int) -> String {
        var out = ""
        for turn in turns {
            let line = "\(turn.displayName): \(turn.text)\n"
            if out.count + line.count > limit { break }
            out += line
        }
        return out
    }

    // MARK: - Lenient parsing

    /// Parse the sectioned response. Tolerant: if the headers are missing,
    /// the entire content becomes the overview so we still return a usable
    /// summary rather than throwing.
    static func parse(_ content: String) -> MeetingSummary {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var section: String? = nil
        var overviewLines: [String] = []
        var keyPoints: [String] = []
        var actionItems: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let upper = trimmed.uppercased()
            if upper.hasPrefix("OVERVIEW") { section = "overview"; continue }
            if upper.hasPrefix("KEY POINTS") || upper.hasPrefix("KEY DISCUSSION") { section = "key"; continue }
            if upper.hasPrefix("ACTION ITEMS") || upper.hasPrefix("ACTIONS") { section = "action"; continue }
            if trimmed.isEmpty { continue }

            switch section {
            case "overview":
                overviewLines.append(trimmed)
            case "key":
                if let bullet = bulletText(trimmed) { keyPoints.append(bullet) }
            case "action":
                if let bullet = bulletText(trimmed), bullet.lowercased() != "none" {
                    actionItems.append(bullet)
                }
            default:
                overviewLines.append(trimmed)
            }
        }

        return MeetingSummary(
            overview: overviewLines.joined(separator: " "),
            keyPoints: keyPoints,
            actionItems: actionItems,
            generator: "Apple Foundation Models"
        )
    }

    /// Strip a leading bullet marker (`-`, `*`, `•`, or `1.`) if present.
    private static func bulletText(_ line: String) -> String? {
        var s = line
        for marker in ["- ", "* ", "• ", "– "] where s.hasPrefix(marker) {
            s.removeFirst(marker.count)
            return s.trimmingCharacters(in: .whitespaces)
        }
        // Numbered list: "1. text"
        if let dot = s.firstIndex(of: "."),
           Int(s[s.startIndex..<dot]) != nil {
            return String(s[s.index(after: dot)...]).trimmingCharacters(in: .whitespaces)
        }
        return s.trimmingCharacters(in: .whitespaces).isEmpty ? nil : s
    }
}
#endif
