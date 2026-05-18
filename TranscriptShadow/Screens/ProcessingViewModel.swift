// @implements SCR-003, UJ-001, ARC-001
// View-model for the SCR-003 processing view. Runs the pipeline:
//   1. TranscriptionService.transcribe       (0-60% via stage 1)
//   2. DiarizationService.diarize            (60-90% via stage 2)
//   3. TranscriptFormatter.format            (snap to 95%)
//   4. TranscriptStore.save                  (snap to 100%)
//   5. (optional) ObsidianExporter.export    (non-fatal on failure)
// `cancel()` propagates `Task.cancel()` through every awaited service.

import Combine
import Foundation

@MainActor
final class ProcessingViewModel: ObservableObject {
    @Published var title: String = "Q3 Planning · Eng + Design"
    @Published var elapsed: String = "47:12 captured"
    @Published var estimatedRemaining: String = ""
    @Published var stages: [PipelineStage] = ProcessingView.mockStages
    @Published var error: String?
    @Published var isRunning: Bool = false

    let env: AppEnvironment
    var onComplete: ((UUID) -> Void)?
    var onCancel: (() -> Void)?

    private var pipelineTask: Task<Void, Never>?

    init(env: AppEnvironment) {
        self.env = env
    }

    /// Called by SCR-003 in `.task(id: audioURL)`. A nil/already-handled
    /// URL is treated as the demo flow (canned mock stages stay
    /// visible).
    func start(audioURL: URL) {
        pipelineTask?.cancel()
        pipelineTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.runPipeline(audioURL: audioURL)
            self.pipelineTask = nil
        }
    }

    func cancel() {
        pipelineTask?.cancel()
        pipelineTask = nil
        onCancel?()
    }

    // MARK: - Pipeline

    private func runPipeline(audioURL: URL) async {
        isRunning = true
        defer { isRunning = false }
        error = nil

        let recordingTitle = Self.makeTitle(audioURL: audioURL)
        title = recordingTitle
        elapsed = "Processing locally"
        estimatedRemaining = ""

        let model = (try? await env.settings.read(.whisperModel)) ?? .baseEN
        stages = [
            PipelineStage(id: "transcribe",
                          label: "Transcribing",
                          sub: "WhisperKit · \(model.rawValue)",
                          percent: 0,
                          status: .active),
            PipelineStage(id: "diarize",
                          label: "Identifying speakers",
                          sub: "pyannote · sidecar",
                          percent: 0,
                          status: .waiting),
            PipelineStage(id: "format",
                          label: "Saving transcript",
                          sub: "merge · markdown · sqlite",
                          percent: 0,
                          status: .waiting),
        ]

        do {
            try await env.transcription.prepare(model: model)
            try Task.checkCancellation()

            let transcript = try await env.transcription.transcribe(
                audioURL: audioURL,
                model: model
            ) { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.updateStage(id: "transcribe", percent: Int(progress * 100), status: progress >= 1 ? .done : .active)
                }
            }
            updateStage(id: "transcribe", percent: 100, status: .done)
            try Task.checkCancellation()

            updateStage(id: "diarize", percent: 0, status: .active)
            let diarization = try await env.diarization.diarize(audioURL: audioURL) { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.updateStage(id: "diarize", percent: Int(progress * 100), status: progress >= 1 ? .done : .active)
                }
            }
            updateStage(id: "diarize", percent: 100, status: .done)
            try Task.checkCancellation()

            updateStage(id: "format", percent: 30, status: .active)
            let formatted = try env.formatter.format(
                transcription: transcript,
                diarization: diarization,
                speakerNames: [:]
            )
            updateStage(id: "format", percent: 70, status: .active)
            try Task.checkCancellation()

            let recordingDate = Date()
            let stored = try await env.transcripts.save(
                formatted: formatted,
                title: recordingTitle,
                date: recordingDate
            )
            updateStage(id: "format", percent: 100, status: .done)

            // Auto-export — non-fatal. If the user has the toggle off
            // or the vault path isn't set, skip silently.
            await autoExportIfEnabled(
                stored: stored,
                formatted: formatted,
                title: recordingTitle,
                date: recordingDate
            )

            onComplete?(stored.id)
        } catch is CancellationError {
            error = "Cancelled"
            onCancel?()
        } catch {
            self.error = describe(error)
            // Mark the active stage as error
            markActiveStageError()
        }
    }

    private func autoExportIfEnabled(
        stored: StoredTranscript,
        formatted: FormattedTranscript,
        title: String,
        date: Date
    ) async {
        guard (try? await env.settings.read(.autoExport)) == true,
              let pathString = try? await env.settings.read(.obsidianVaultPath),
              !pathString.isEmpty
        else { return }
        let subfolder = (try? await env.settings.read(.obsidianSubfolder)) ?? "Meetings"
        do {
            let exportedURL = try env.exporter.export(
                transcript: formatted,
                title: title,
                date: date,
                vaultPath: URL(fileURLWithPath: pathString),
                subfolder: subfolder.isEmpty ? nil : subfolder
            )
            try? await env.transcripts.markExported(id: stored.id, to: exportedURL)
        } catch {
            // Best-effort. Future EPIC can surface this in the UI.
        }
    }

    private func updateStage(id: String, percent: Int, status: PipelineStage.Status) {
        if let idx = stages.firstIndex(where: { $0.id == id }) {
            stages[idx] = PipelineStage(
                id: stages[idx].id,
                label: stages[idx].label,
                sub: stages[idx].sub,
                percent: max(min(percent, 100), 0),
                status: status
            )
        }
    }

    private func markActiveStageError() {
        if let idx = stages.firstIndex(where: { $0.status == .active }) {
            stages[idx] = PipelineStage(
                id: stages[idx].id,
                label: stages[idx].label,
                sub: stages[idx].sub,
                percent: stages[idx].percent,
                status: .error
            )
        }
    }

    private static func makeTitle(audioURL: URL) -> String {
        let dateString = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .medium,
            timeStyle: .short
        )
        return "Recording · \(dateString)"
    }

    private func describe(_ error: Error) -> String {
        let msg = (error as? LocalizedError)?.errorDescription ?? "\(error)"
        return msg
    }
}
