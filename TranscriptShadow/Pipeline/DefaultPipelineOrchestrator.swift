// @implements ARC-001, ARC-003, API-301, BR-101
// Production pipeline orchestrator. Sequences transcribe→diarize→
// format→save→optional export per ARC-001's strict-serial v0.7
// architecture and emits a monotonic aggregate progress fraction.
//
// Weighting (stays aligned with PipelineOrchestrator.swift comment):
//   transcribe   → [0.0, 0.6)
//   diarize      → [0.6, 0.9)
//   format       → [0.9, 0.92)
//   save         → [0.92, 0.97)
//   export       → [0.97, 1.0]
//
// Cleanup discipline (API-301): a single `defer` deletes the temp WAV
// on every exit path — success, cancel, OR throw. Cancellation
// pre-catches `CancellationError` and surfaces it as
// `OrchestrationError.cancelled`, never collapsing it into a generic
// stage failure (EPIC-03 lesson).

import Foundation
import os

public final class DefaultPipelineOrchestrator: PipelineOrchestrator, @unchecked Sendable {
    private static let log = Logger(subsystem: "ai.gearheart.TranscriptShadow", category: "pipeline")

    private let transcription: any TranscriptionService
    private let diarization: any DiarizationService
    private let formatter: any TranscriptFormatter
    private let transcripts: any TranscriptStore
    private let settings: any SettingsStore
    private let exporter: any ObsidianExporter
    private let summarizer: any SummarizationService
    private let cleanup: any TempAudioCleanup
    private let titleFactory: @Sendable (Date) -> String

    public init(
        transcription: any TranscriptionService,
        diarization: any DiarizationService,
        formatter: any TranscriptFormatter,
        transcripts: any TranscriptStore,
        settings: any SettingsStore,
        exporter: any ObsidianExporter,
        summarizer: any SummarizationService = DefaultSummarizationService(),
        cleanup: any TempAudioCleanup,
        titleFactory: @escaping @Sendable (Date) -> String = DefaultPipelineOrchestrator.defaultTitle
    ) {
        self.transcription = transcription
        self.diarization = diarization
        self.formatter = formatter
        self.transcripts = transcripts
        self.settings = settings
        self.exporter = exporter
        self.summarizer = summarizer
        self.cleanup = cleanup
        self.titleFactory = titleFactory
    }

    public func process(
        audioURL: URL,
        progress: @escaping @Sendable (PipelineProgress) -> Void
    ) async throws -> PipelineResult {
        // Single cleanup point. Codex Gate 6 P2 fix — cleanup is now
        // awaited (not detached) so callers can rely on the temp WAV
        // being gone the instant `process` returns or throws (BR-102 /
        // API-301).
        let result: Result<PipelineResult, Error>
        do {
            let outcome = try await runStages(audioURL: audioURL, progress: progress)
            result = .success(outcome)
        } catch {
            result = .failure(error)
        }
        await cleanup.delete(url: audioURL)
        return try result.get()
    }

    private func runStages(
        audioURL: URL,
        progress: @escaping @Sendable (PipelineProgress) -> Void
    ) async throws -> PipelineResult {
        let model = (try? await settings.read(.whisperModel)) ?? .baseEN
        // Prepare — service errors here are still transcription-stage.
        do {
            try await transcription.prepare(model: model)
        } catch is CancellationError {
            throw OrchestrationError.cancelled
        } catch {
            throw OrchestrationError.transcriptionFailed("\(error)")
        }
        try Task.checkCancellation()

        // Stage 1: Transcribe [0.0 → 0.6]
        let transcript: Transcript
        do {
            transcript = try await transcription.transcribe(
                audioURL: audioURL,
                model: model
            ) { fraction in
                let agg = max(0, min(fraction, 1)) * 0.6
                progress(PipelineProgress(stage: .transcribe, stageFraction: fraction, aggregateFraction: agg))
            }
        } catch is CancellationError {
            throw OrchestrationError.cancelled
        } catch {
            throw OrchestrationError.transcriptionFailed("\(error)")
        }
        progress(PipelineProgress(stage: .transcribe, stageFraction: 1, aggregateFraction: 0.6))
        try Task.checkCancellation()

        // Stage 2: Diarize [0.6 → 0.9] — Codex Gate 6 P2 fix: per-stage
        // error mapping so SCR-003 reports speaker-identification
        // failures distinctly from transcription failures, and cancel
        // during diarize still surfaces .cancelled.
        let diarizationResult: DiarizationResult
        do {
            diarizationResult = try await diarization.diarize(audioURL: audioURL) { fraction in
                let agg = 0.6 + max(0, min(fraction, 1)) * 0.3
                progress(PipelineProgress(stage: .diarize, stageFraction: fraction, aggregateFraction: agg))
            }
        } catch is CancellationError {
            throw OrchestrationError.cancelled
        } catch {
            throw OrchestrationError.diarizationFailed("\(error)")
        }
        progress(PipelineProgress(stage: .diarize, stageFraction: 1, aggregateFraction: 0.9))
        try Task.checkCancellation()

        // Stage 3: Format [0.9 → 0.92]
        let formatted: FormattedTranscript
        do {
            formatted = try formatter.format(
                transcription: transcript,
                diarization: diarizationResult,
                speakerNames: [:]
            )
        } catch {
            throw OrchestrationError.formattingFailed("\(error)")
        }
        progress(PipelineProgress(stage: .format, stageFraction: 0.5, aggregateFraction: 0.91))

        // Stage 3b: On-device summary (API-401 / FEA-007 / BR-104) — runs
        // within the format span, best-effort. A missing/failed summarizer
        // must never block the save, so every error is swallowed and the
        // un-summarized transcript proceeds (same non-fatal discipline as
        // auto-export). The summary is embedded into the markdown so it
        // reaches both SQLite and the Obsidian export with no schema change.
        let enriched = await maybeSummarize(formatted)
        progress(PipelineProgress(stage: .format, stageFraction: 1, aggregateFraction: 0.92))
        try Task.checkCancellation()

        // Stage 4: Save [0.92 → 0.97]
        let now = Date()
        let title = titleFactory(now)
        let stored: StoredTranscript
        do {
            stored = try await transcripts.save(formatted: enriched, title: title, date: now)
        } catch is CancellationError {
            throw OrchestrationError.cancelled
        } catch {
            throw OrchestrationError.saveFailed("\(error)")
        }
        progress(PipelineProgress(stage: .save, stageFraction: 1, aggregateFraction: 0.97))

        // Stage 5: Export [0.97 → 1.0] — best-effort. Exports `enriched`
        // so the Obsidian note carries the embedded summary. A failure here
        // is non-fatal: maybeAutoExport returns a warning (F-1) rather than
        // throwing, so the saved transcript is never invalidated.
        let exportWarning = await maybeAutoExport(
            stored: stored,
            formatted: enriched,
            title: title,
            date: now,
            progress: progress
        )

        return PipelineResult(id: stored.id, exportWarning: exportWarning)
    }

    // MARK: - Summary (API-401 / FEA-007)

    /// Runs the on-device summarizer when `summarizeOnComplete` is enabled,
    /// then embeds the rendered summary above the transcript body. Returns
    /// the original transcript unchanged if summarization is off, the
    /// transcript has no turns, the summary is empty, or the engine throws
    /// — summarization is never allowed to fail the pipeline (BR-104 is a
    /// quality feature, not a gate).
    private func maybeSummarize(_ formatted: FormattedTranscript) async -> FormattedTranscript {
        guard (try? await settings.read(.summarizeOnComplete)) == true else { return formatted }
        guard !formatted.turns.isEmpty else { return formatted }
        do {
            let summary = try await summarizer.summarize(transcript: formatted)
            guard !summary.isEmpty else { return formatted }
            let merged = SummaryMarkdownRenderer.prepend(summary, to: formatted.markdown)
            return formatted.replacingMarkdown(merged)
        } catch {
            return formatted
        }
    }

    // MARK: - Auto export

    /// Returns nil when export is disabled/unconfigured or succeeds; returns a
    /// user-facing warning when an *enabled* export fails. Never throws — the
    /// save is already durable and must not be invalidated (EPIC-08 contract).
    /// The failure was previously swallowed with no log and no UI signal
    /// (F-1, codebase review 2026-05-30); it is now logged and surfaced.
    private func maybeAutoExport(
        stored: StoredTranscript,
        formatted: FormattedTranscript,
        title: String,
        date: Date,
        progress: @Sendable (PipelineProgress) -> Void
    ) async -> String? {
        guard (try? await settings.read(.autoExport)) == true,
              let path = try? await settings.read(.obsidianVaultPath),
              !path.isEmpty
        else {
            // No auto-export → snap stage 5 to done so the bar reaches 100%.
            progress(PipelineProgress(stage: .export, stageFraction: 1, aggregateFraction: 1.0))
            return nil
        }
        let subfolder = (try? await settings.read(.obsidianSubfolder)) ?? "Meetings"
        do {
            let url = try exporter.export(
                transcript: formatted,
                title: title,
                date: date,
                vaultPath: URL(fileURLWithPath: path),
                subfolder: subfolder.isEmpty ? nil : subfolder
            )
            try? await transcripts.markExported(id: stored.id, to: url)
            progress(PipelineProgress(stage: .export, stageFraction: 1, aggregateFraction: 1.0))
            return nil
        } catch {
            // Non-fatal — the transcript is saved. Log + return a warning
            // (F-1) instead of swallowing it; never invalidate the save. Snap
            // progress to 1 so the UI doesn't hang at 97 %.
            Self.log.warning("Auto-export to Obsidian failed (transcript \(stored.id.uuidString, privacy: .public) still saved): \(String(describing: error), privacy: .public)")
            progress(PipelineProgress(stage: .export, stageFraction: 1, aggregateFraction: 1.0))
            return Self.exportWarningMessage(error)
        }
    }

    /// User-facing copy for a non-fatal export failure (F-1).
    private static func exportWarningMessage(_ error: Error) -> String {
        let detail = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        return "Transcript saved, but export to your Obsidian vault failed: \(detail)"
    }

    // MARK: - Title

    public static func defaultTitle(_ date: Date) -> String {
        let formatter = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
        return "Recording · \(formatter)"
    }
}
