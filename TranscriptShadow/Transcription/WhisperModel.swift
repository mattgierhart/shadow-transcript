// @implements API-101, INT-101, TECH-002
import Foundation

/// English-only Whisper model variants the app exposes (BR-202).
/// Names match the directory layout WhisperKit downloads from Hugging Face
/// (e.g. `openai_whisper-base.en`).
public enum WhisperModel: String, Sendable, Equatable, CaseIterable, Codable {
    /// ~148 MB — default. Good speed/quality balance on Apple Silicon.
    case baseEN = "openai_whisper-base.en"
    /// ~488 MB — higher accuracy, slower.
    case smallEN = "openai_whisper-small.en"
    /// ~1.5 GB — best accuracy, slowest.
    case mediumEN = "openai_whisper-medium.en"

    public static let `default` = WhisperModel.baseEN

    public var displayName: String {
        switch self {
        case .baseEN: return "Whisper Base (English)"
        case .smallEN: return "Whisper Small (English)"
        case .mediumEN: return "Whisper Medium (English)"
        }
    }

    /// Approximate on-disk size after download — informational only.
    public var approximateSizeBytes: Int64 {
        switch self {
        case .baseEN: return 148_000_000
        case .smallEN: return 488_000_000
        case .mediumEN: return 1_500_000_000
        }
    }
}
