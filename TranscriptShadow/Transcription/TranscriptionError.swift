// @implements API-101
import Foundation

public enum TranscriptionError: Error, Equatable, Sendable {
    case audioFileMissing(url: URL)
    case audioFileUnreadable(url: URL, reason: String)
    case modelLoadFailed(model: WhisperModel, reason: String)
    case modelDownloadFailed(model: WhisperModel, reason: String)
    case transcriptionFailed(reason: String)
    case cancelled
    case unsupportedLanguage(requested: String)
}

extension TranscriptionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .audioFileMissing(let url):
            return "Audio file not found at \(url.lastPathComponent)."
        case .audioFileUnreadable(let url, let reason):
            return "Could not read audio at \(url.lastPathComponent): \(reason)"
        case .modelLoadFailed(let model, let reason):
            return "Failed to load \(model.displayName): \(reason)"
        case .modelDownloadFailed(let model, let reason):
            return "Failed to download \(model.displayName): \(reason)"
        case .transcriptionFailed(let reason):
            return "Transcription failed: \(reason)"
        case .cancelled:
            return "Transcription was cancelled."
        case .unsupportedLanguage(let requested):
            return "Language \(requested) is not supported. The MVP is English-only (BR-202)."
        }
    }
}
