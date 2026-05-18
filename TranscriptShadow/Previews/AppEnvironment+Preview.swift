// @implements ARC-001
// Preview factory for AppEnvironment. Bundles every Preview* fake into a
// fully-functional in-memory `AppEnvironment`. Used by `#Preview { … }`
// blocks and by view-model unit tests so neither has to construct each
// fake by hand. Production code uses `AppEnvironment.live()` from
// `AppEnvironment.swift` instead.

import Foundation

public extension AppEnvironment {
    static func preview(
        seedTranscripts: [StoredTranscript] = []
    ) -> AppEnvironment {
        AppEnvironment(
            audioCapture: PreviewAudioCaptureService(),
            transcription: PreviewTranscriptionService(),
            diarization: FakeDiarizationService(),
            formatter: PreviewTranscriptFormatter(),
            transcripts: PreviewTranscriptStore(seed: seedTranscripts),
            settings: PreviewSettingsStore(),
            exporter: PreviewObsidianExporter()
        )
    }
}
