// @implements ARC-001, ARC-003
// Typed error path for the EPIC-08 PipelineOrchestrator. Distinguishes
// `.cancelled` (a meaningful product state, not an error) from per-stage
// failure causes so SCR-003 can render distinct error variants.

import Foundation

public enum OrchestrationError: Error, Equatable, LocalizedError {
    case audioFileMissing(URL)
    case transcriptionFailed(String)
    case diarizationFailed(String)
    case formattingFailed(String)
    case saveFailed(String)
    /// `.cancelled` is NOT bundled into the other cases by design — the
    /// pipeline pre-catches `CancellationError` before mapping to one
    /// of the failure cases. Cancellation is a product state.
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .audioFileMissing(let url): return "Audio file not found: \(url.lastPathComponent)"
        case .transcriptionFailed(let reason): return "Transcription failed: \(reason)"
        case .diarizationFailed(let reason): return "Speaker identification failed: \(reason)"
        case .formattingFailed(let reason): return "Formatting failed: \(reason)"
        case .saveFailed(let reason): return "Couldn't save transcript: \(reason)"
        case .cancelled: return "Cancelled"
        }
    }
}
