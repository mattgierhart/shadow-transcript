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

public final class DefaultPipelineOrchestrator: PipelineOrchestrator, @unchecked Sendable {
    private let transcription: any TranscriptionService
    private let diarization: any DiarizationService
    private let formatter: any TranscriptFormatter
    private let transcripts: any TranscriptStore
    private let settings: any SettingsStore
    private let exporter: any ObsidianExporter
    private let cleanup: any TempAudioCleanup
    private let titleFactory: @Sendable (Date) -> String

    public init(
        transcription: any TranscriptionService,
        diarization: any DiarizationService,
        formatter: any TranscriptFormatter,
        transcripts: any TranscriptStore,
        settings: any SettingsStore,
        exporter: any ObsidianExporter,
        cleanup: any TempAudioCleanup,
        titleFactory: @escaping @Sendable (Date) -> String = DefaultPipelineOrchestrator.defaultTitle
    ) {
        self.transcription = transcription
        self.diarization = diarization
        self.formatter = formatter
        self.transcripts = transcripts
        self.settings = settings
        self.exporter = exporter
        self.cleanup = cleanup
        self.titleFactory = titleFactory
    }

    public func process(
        audioURL: URL,
        progress: @escaping @Sendable (PipelineProgress) -> Void
    ) async throws -> UUID {
        // Single cleanup point. Fires on success, cancel, and any
        // throw. Detached so a cancelled outer Task still runs the
        // cleanup (Task.detached is not cancelled by the parent).
        defer {
            let url = audioURL
            let cleanup = self.cleanup
            Task.detached { await cleanup.delete(url: url) }
        }

        do {
            let model = (try? await settings.read(.whisperModel)) ?? .baseEN
            try await transcription.prepare(model: model)
            try Task.checkCancellation()

            // Stage 1: Transcribe [0.0 → 0.6]
            let transcript = try await transcription.transcribe(
                audioURL: audioURL,
                model: model
            ) { fraction in
                let agg = max(0, min(fraction, 1)) * 0.6
                progress(PipelineProgress(stage: .transcribe, stageFraction: fraction, aggregateFraction: agg))
            }
            progress(PipelineProgress(stage: .transcribe, stageFraction: 1, aggregateFraction: 0.6))
            try Task.checkCancellation()

            // Stage 2: Diarize [0.6 → 0.9]
            let diarization = try await diarization.diarize(audioURL: audioURL) { fraction in
                let agg = 0.6 + max(0, min(fraction, 1)) * 0.3
                progress(PipelineProgress(stage: .diarize, stageFraction: fraction, aggregateFraction: agg))
            }
            progress(PipelineProgress(stage: .diarize, stageFraction: 1, aggregateFraction: 0.9))
            try Task.checkCancellation()

            // Stage 3: Format [0.9 → 0.92]
            let formatted: FormattedTranscript
            do {
                formatted = try formatter.format(
                    transcription: transcript,
                    diarization: diarization,
                    speakerNames: [:]
                )
            } catch {
                throw OrchestrationError.formattingFailed("\(error)")
            }
            progress(PipelineProgress(stage: .format, stageFraction: 1, aggregateFraction: 0.92))
            try Task.checkCancellation()

            // Stage 4: Save [0.92 → 0.97]
            let now = Date()
            let title = titleFactory(now)
            let stored: StoredTranscript
            do {
                stored = try await transcripts.save(formatted: formatted, title: title, date: now)
            } catch is CancellationError {
                throw OrchestrationError.cancelled
            } catch {
                throw OrchestrationError.saveFailed("\(error)")
            }
            progress(PipelineProgress(stage: .save, stageFraction: 1, aggregateFraction: 0.97))

            // Stage 5: Export [0.97 → 1.0] — best-effort
            await maybeAutoExport(
                stored: stored,
                formatted: formatted,
                title: title,
                date: now,
                progress: progress
            )

            return stored.id
        } catch is CancellationError {
            throw OrchestrationError.cancelled
        } catch let error as OrchestrationError {
            throw error
        } catch {
            // Any service throw at the transcribe/diarize stages flows here.
            throw OrchestrationError.transcriptionFailed("\(error)")
        }
    }

    // MARK: - Auto export

    private func maybeAutoExport(
        stored: StoredTranscript,
        formatted: FormattedTranscript,
        title: String,
        date: Date,
        progress: @Sendable (PipelineProgress) -> Void
    ) async {
        guard (try? await settings.read(.autoExport)) == true,
              let path = try? await settings.read(.obsidianVaultPath),
              !path.isEmpty
        else {
            // No auto-export → snap stage 5 to done so the bar reaches 100%.
            progress(PipelineProgress(stage: .export, stageFraction: 1, aggregateFraction: 1.0))
            return
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
        } catch {
            // Non-fatal — the transcript is saved. Snap progress to 1
            // so the UI doesn't hang at 97 %.
            progress(PipelineProgress(stage: .export, stageFraction: 1, aggregateFraction: 1.0))
        }
    }

    // MARK: - Title

    public static func defaultTitle(_ date: Date) -> String {
        let formatter = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
        return "Recording · \(formatter)"
    }
}
