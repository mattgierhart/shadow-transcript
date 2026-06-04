// @implements API-401, FEA-007, BR-104, TECH-008
// Production `SummarizationService`. Prefers Apple's on-device Foundation
// Models (macOS 26+, Apple Intelligence) and falls back to the
// deterministic `ExtractiveSummarizer` whenever the LLM is unavailable or
// errors. The whole thing is on-device — BR-104/BR-101 hold regardless of
// which engine runs.
//
// Engine selection is resolved at runtime, not construction, so a single
// build runs the LLM on capable machines and the extractive path on
// everything else (the deployment target is macOS 15; FoundationModels is
// macOS 26-only, so the `#if canImport` guard keeps the macOS-15 SDK build
// compiling — see TECH-008).

import Foundation

public struct DefaultSummarizationService: SummarizationService, Sendable {
    private let fallback: any SummarizationService

    public init(fallback: any SummarizationService = ExtractiveSummarizer()) {
        self.fallback = fallback
    }

    public func summarize(transcript: FormattedTranscript) async throws -> MeetingSummary {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            do {
                return try await FoundationModelsSummarizer().summarize(transcript: transcript)
            } catch {
                // LLM unavailable (Apple Intelligence off, model not ready)
                // or a generation failure — degrade to the deterministic
                // extractive summary rather than dropping the FEA-007
                // surface entirely.
            }
        }
        #endif
        return try await fallback.summarize(transcript: transcript)
    }
}
