// @implements API-401, FEA-007, BR-104, ARC-001
// Public contract for the on-device summarization stage (API-401). The
// orchestrator calls `summarize` after `TranscriptFormatter.format` and
// before `TranscriptStore.save`, then prepends the rendered summary to
// the transcript markdown. The call is **best-effort** — the orchestrator
// pre-catches every error and proceeds with the un-summarized transcript,
// so a missing/unavailable model never blocks a save (mirrors the
// auto-export non-fatal discipline from EPIC-08).

import Foundation

public protocol SummarizationService: Sendable {
    /// Produce a `MeetingSummary` from a formatted transcript. Throws
    /// `SummarizationError` for typed failures; the orchestrator treats
    /// any throw as "no summary" and continues.
    func summarize(transcript: FormattedTranscript) async throws -> MeetingSummary
}

public enum SummarizationError: Error, Equatable {
    /// The transcript had no usable turns/text to summarize.
    case emptyTranscript
    /// The chosen engine (e.g. Apple Foundation Models) is not available
    /// on this OS / device / Apple-Intelligence state.
    case modelUnavailable(String)
    /// The engine ran but produced an error or unparseable output.
    case generationFailed(String)
}

// MARK: - Markdown embedding

/// Renders a `MeetingSummary` into a markdown block and prepends it to a
/// transcript body. Kept separate from `MeetingSummary` so the rendering
/// shape can evolve without touching the model. Action items render as
/// GitHub/Obsidian task checkboxes so they're actionable in the vault.
public enum SummaryMarkdownRenderer {
    public static func render(_ summary: MeetingSummary) -> String {
        var out = "## Summary\n\n"
        let overview = summary.overview.trimmingCharacters(in: .whitespacesAndNewlines)
        if !overview.isEmpty {
            out += overview + "\n\n"
        }
        if !summary.keyPoints.isEmpty {
            out += "### Key points\n\n"
            for point in summary.keyPoints {
                out += "- \(point)\n"
            }
            out += "\n"
        }
        if !summary.actionItems.isEmpty {
            out += "### Action items\n\n"
            for item in summary.actionItems {
                out += "- [ ] \(item)\n"
            }
            out += "\n"
        }
        out += "_Generated on-device · \(summary.generator)_"
        return out
    }

    /// Prepend the summary block above the transcript body, separated by a
    /// horizontal rule so the boundary is obvious in Obsidian.
    public static func prepend(_ summary: MeetingSummary, to markdown: String) -> String {
        render(summary) + "\n\n---\n\n" + markdown
    }
}

// MARK: - FormattedTranscript convenience

public extension FormattedTranscript {
    /// Returns a copy with `markdown` replaced. Used by the orchestrator to
    /// embed the summary block without mutating the immutable value type or
    /// touching `TranscriptFormatter`.
    func replacingMarkdown(_ newMarkdown: String) -> FormattedTranscript {
        FormattedTranscript(
            markdown: newMarkdown,
            metadata: metadata,
            speakerMap: speakerMap,
            warnings: warnings,
            turns: turns
        )
    }
}
