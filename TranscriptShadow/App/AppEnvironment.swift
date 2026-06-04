// @implements ARC-001, ARC-002, ARC-003, FEA-001→006
// @see SoT/SoT.TECHNICAL_DECISIONS.md ARC-001
//
// Dependency container for the SwiftUI layer. Every screen view-model reads
// services through `AppEnvironment` instead of constructing implementations
// directly. Two factories: `live()` (real implementations, used in
// TranscriptShadowApp) and `preview()` (in-memory fakes, used in #Preview).
//
// AppEnvironment is `Sendable` because each service protocol refines
// `Sendable` and the container holds them through their existentials.

import Foundation

public struct AppEnvironment: Sendable {
    public let audioCapture: any AudioCaptureService
    public let transcription: any TranscriptionService
    public let diarization: any DiarizationService
    public let formatter: any TranscriptFormatter
    public let transcripts: any TranscriptStore
    public let settings: any SettingsStore
    public let exporter: any ObsidianExporter
    public let summarizer: any SummarizationService
    public let cleanup: any TempAudioCleanup
    public let pipeline: any PipelineOrchestrator

    public init(
        audioCapture: any AudioCaptureService,
        transcription: any TranscriptionService,
        diarization: any DiarizationService,
        formatter: any TranscriptFormatter,
        transcripts: any TranscriptStore,
        settings: any SettingsStore,
        exporter: any ObsidianExporter,
        summarizer: (any SummarizationService)? = nil,
        cleanup: (any TempAudioCleanup)? = nil,
        pipeline: (any PipelineOrchestrator)? = nil
    ) {
        let resolvedCleanup = cleanup ?? DefaultTempAudioCleanup()
        let resolvedSummarizer = summarizer ?? DefaultSummarizationService()
        self.audioCapture = audioCapture
        self.transcription = transcription
        self.diarization = diarization
        self.formatter = formatter
        self.transcripts = transcripts
        self.settings = settings
        self.exporter = exporter
        self.summarizer = resolvedSummarizer
        self.cleanup = resolvedCleanup
        self.pipeline = pipeline ?? DefaultPipelineOrchestrator(
            transcription: transcription,
            diarization: diarization,
            formatter: formatter,
            transcripts: transcripts,
            settings: settings,
            exporter: exporter,
            summarizer: resolvedSummarizer,
            cleanup: resolvedCleanup
        )
    }
}

// MARK: - Live factory

public extension AppEnvironment {
    /// Real-services factory used by `TranscriptShadowApp` at launch. Opens
    /// the on-disk SQLite, runs migrations, constructs the WhisperKit-backed
    /// transcription service, and wires the bundled pyannote sidecar.
    static func live() throws -> AppEnvironment {
        let database = try AppDatabase.openOnDisk()
        try database.migrate()

        let transcription: any TranscriptionService
        #if canImport(WhisperKit)
        transcription = try DefaultTranscriptionService()
        #else
        transcription = PreviewTranscriptionService()
        #endif

        return AppEnvironment(
            audioCapture: DefaultAudioCaptureService(),
            transcription: transcription,
            diarization: PyannoteSidecarDiarizationService(),
            formatter: DefaultTranscriptFormatter(),
            transcripts: DefaultTranscriptStore(database: database),
            settings: DefaultSettingsStore(database: database),
            exporter: DefaultObsidianExporter()
        )
    }
}
