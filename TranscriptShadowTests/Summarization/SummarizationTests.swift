// @implements API-401, FEA-007, BR-104, TEST-601, TEST-602
// Tests for the on-device summarization stage: the deterministic
// ExtractiveSummarizer (oracle), the markdown renderer, DefaultSummarization
// Service selection, and the orchestrator's non-fatal embedding behavior.

import XCTest
@testable import TranscriptShadow

final class SummarizationTests: XCTestCase {

    // MARK: - Fixtures

    private func transcript(turns: [TranscriptTurn]) -> FormattedTranscript {
        FormattedTranscript(
            markdown: turns.map { "**\($0.displayName)** [00:00:00]:\n\($0.text)" }.joined(separator: "\n\n"),
            metadata: TranscriptMetadata(
                durationSeconds: 120,
                speakerCount: Set(turns.map(\.canonicalSpeaker)).count,
                language: "en",
                model: .baseEN,
                wordCount: turns.reduce(0) { $0 + $1.text.split(separator: " ").count },
                turnCount: turns.count
            ),
            speakerMap: Dictionary(uniqueKeysWithValues: turns.map { ($0.canonicalSpeaker, $0.displayName) }),
            warnings: [],
            turns: turns
        )
    }

    private func turn(_ speaker: String, _ name: String, _ text: String, start: TimeInterval = 0) -> TranscriptTurn {
        TranscriptTurn(canonicalSpeaker: speaker, displayName: name, startSeconds: start, endSeconds: start + 5, text: text)
    }

    private var sampleTranscript: FormattedTranscript {
        transcript(turns: [
            turn("SPEAKER_00", "Alice", "Welcome everyone to the Q3 planning meeting today.", start: 0),
            turn("SPEAKER_01", "Bob", "Thanks Alice. I think the biggest open question is the launch date for the new release.", start: 6),
            turn("SPEAKER_00", "Alice", "Agreed. We need to lock the scope before we can commit to a date.", start: 14),
            turn("SPEAKER_01", "Bob", "I'll draft the scope document and send it out by tomorrow for review.", start: 22),
            turn("SPEAKER_00", "Alice", "Great. Let's schedule a follow-up next week to finalize everything.", start: 30)
        ])
    }

    // MARK: - ExtractiveSummarizer (TEST-601)

    func test_extractive_producesNonEmptySummary() async throws {
        let summary = try await ExtractiveSummarizer().summarize(transcript: sampleTranscript)
        XCTAssertFalse(summary.isEmpty)
        XCTAssertFalse(summary.overview.isEmpty)
        XCTAssertFalse(summary.keyPoints.isEmpty)
        XCTAssertEqual(summary.generator, "Extractive (on-device)")
    }

    func test_extractive_overviewReportsSpeakerAndTurnCounts() async throws {
        let summary = try await ExtractiveSummarizer().summarize(transcript: sampleTranscript)
        XCTAssertTrue(summary.overview.contains("2 speakers"), "Overview: \(summary.overview)")
        XCTAssertTrue(summary.overview.contains("5 turns"), "Overview: \(summary.overview)")
    }

    func test_extractive_detectsActionItems() async throws {
        let summary = try await ExtractiveSummarizer().summarize(transcript: sampleTranscript)
        // "I'll draft … send it out by tomorrow" + "Let's schedule a follow-up"
        XCTAssertGreaterThanOrEqual(summary.actionItems.count, 1, "Items: \(summary.actionItems)")
        let joined = summary.actionItems.joined(separator: " | ").lowercased()
        XCTAssertTrue(joined.contains("draft") || joined.contains("schedule") || joined.contains("follow"),
                      "Expected an action cue in \(summary.actionItems)")
    }

    func test_extractive_isDeterministic() async throws {
        let a = try await ExtractiveSummarizer().summarize(transcript: sampleTranscript)
        let b = try await ExtractiveSummarizer().summarize(transcript: sampleTranscript)
        XCTAssertEqual(a, b, "Extractive summary must be deterministic across runs")
    }

    func test_extractive_emptyTranscriptThrows() async {
        let empty = transcript(turns: [])
        do {
            _ = try await ExtractiveSummarizer().summarize(transcript: empty)
            XCTFail("Expected emptyTranscript throw")
        } catch let error as SummarizationError {
            XCTAssertEqual(error, .emptyTranscript)
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    // MARK: - Markdown rendering

    func test_renderer_emitsSectionsAndCheckboxes() {
        let summary = MeetingSummary(
            overview: "An overview.",
            keyPoints: ["Point one", "Point two"],
            actionItems: ["Do the thing"],
            generator: "Extractive (on-device)"
        )
        let md = SummaryMarkdownRenderer.render(summary)
        XCTAssertTrue(md.contains("## Summary"))
        XCTAssertTrue(md.contains("### Key points"))
        XCTAssertTrue(md.contains("- Point one"))
        XCTAssertTrue(md.contains("### Action items"))
        XCTAssertTrue(md.contains("- [ ] Do the thing"))
        XCTAssertTrue(md.contains("_Generated on-device · Extractive (on-device)_"))
    }

    func test_prepend_putsSummaryAboveBodyWithRule() {
        let merged = SummaryMarkdownRenderer.prepend(.preview, to: "**Alice** [00:00:00]:\nHi")
        XCTAssertTrue(merged.hasPrefix("## Summary"))
        XCTAssertTrue(merged.contains("\n---\n"))
        XCTAssertTrue(merged.hasSuffix("**Alice** [00:00:00]:\nHi"))
    }

    func test_replacingMarkdown_keepsEverythingElse() {
        let original = sampleTranscript
        let replaced = original.replacingMarkdown("NEW BODY")
        XCTAssertEqual(replaced.markdown, "NEW BODY")
        XCTAssertEqual(replaced.metadata, original.metadata)
        XCTAssertEqual(replaced.turns, original.turns)
        XCTAssertEqual(replaced.speakerMap, original.speakerMap)
    }

    // MARK: - DefaultSummarizationService

    func test_default_fallsBackToExtractiveWhenNoLLM() async throws {
        // On the CI macOS-15 SDK FoundationModels isn't importable, so this
        // resolves to the extractive fallback and must still summarize.
        let summary = try await DefaultSummarizationService().summarize(transcript: sampleTranscript)
        XCTAssertFalse(summary.isEmpty)
    }

    // MARK: - Orchestrator embedding (TEST-602)

    func test_orchestrator_embedsSummaryIntoSavedMarkdown() async throws {
        let store = PreviewTranscriptStore()
        let settings = PreviewSettingsStore()
        try await settings.write(.summarizeOnComplete, true)
        let summarizer = PreviewSummarizationService()  // returns .preview

        let orchestrator = DefaultPipelineOrchestrator(
            transcription: PreviewTranscriptionService(),
            diarization: FakeDiarizationService(),
            formatter: PreviewTranscriptFormatter(),
            transcripts: store,
            settings: settings,
            exporter: PreviewObsidianExporter(),
            summarizer: summarizer,
            cleanup: NoopCleanup()
        )

        let id = try await orchestrator.process(audioURL: URL(fileURLWithPath: "/tmp/x.wav"))
        let stored = try await store.fetch(id: id)
        XCTAssertNotNil(stored)
        XCTAssertEqual(summarizer.callCount, 1)
        XCTAssertTrue(stored?.markdown.contains("## Summary") == true,
                      "Saved markdown should carry the embedded summary block")
        XCTAssertTrue(stored?.markdown.contains("Preview transcript text.") == true,
                      "Saved markdown should still contain the transcript body")
    }

    func test_orchestrator_skipsSummaryWhenDisabled() async throws {
        let store = PreviewTranscriptStore()
        let settings = PreviewSettingsStore()
        try await settings.write(.summarizeOnComplete, false)
        let summarizer = PreviewSummarizationService()

        let orchestrator = DefaultPipelineOrchestrator(
            transcription: PreviewTranscriptionService(),
            diarization: FakeDiarizationService(),
            formatter: PreviewTranscriptFormatter(),
            transcripts: store,
            settings: settings,
            exporter: PreviewObsidianExporter(),
            summarizer: summarizer,
            cleanup: NoopCleanup()
        )

        let id = try await orchestrator.process(audioURL: URL(fileURLWithPath: "/tmp/x.wav"))
        let stored = try await store.fetch(id: id)
        XCTAssertEqual(summarizer.callCount, 0, "Summarizer must not run when disabled")
        XCTAssertFalse(stored?.markdown.contains("## Summary") == true)
    }

    func test_orchestrator_summaryFailureIsNonFatal() async throws {
        let store = PreviewTranscriptStore()
        let settings = PreviewSettingsStore()
        try await settings.write(.summarizeOnComplete, true)
        let summarizer = PreviewSummarizationService()
        summarizer.nextError = SummarizationError.generationFailed("boom")

        let orchestrator = DefaultPipelineOrchestrator(
            transcription: PreviewTranscriptionService(),
            diarization: FakeDiarizationService(),
            formatter: PreviewTranscriptFormatter(),
            transcripts: store,
            settings: settings,
            exporter: PreviewObsidianExporter(),
            summarizer: summarizer,
            cleanup: NoopCleanup()
        )

        // Save must still succeed even though summarization threw.
        let id = try await orchestrator.process(audioURL: URL(fileURLWithPath: "/tmp/x.wav"))
        let stored = try await store.fetch(id: id)
        XCTAssertNotNil(stored, "Save must survive a summarizer failure (non-fatal)")
        XCTAssertFalse(stored?.markdown.contains("## Summary") == true)
    }

    // MARK: - Helpers

    private final class NoopCleanup: TempAudioCleanup, @unchecked Sendable {
        func delete(url: URL) async {}
        func scanForOrphans() async {}
        func cleanupAll() async {}
    }
}
