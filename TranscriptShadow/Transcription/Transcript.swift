// @implements API-101
import Foundation

/// One contiguous transcribed segment. Times are measured in seconds from the
/// start of the input audio. `words` may be empty when WhisperKit was run
/// without `wordTimestamps`; the orchestrator always requests them.
public struct TranscriptSegment: Sendable, Equatable {
    public let text: String
    public let start: TimeInterval
    public let end: TimeInterval
    public let words: [WordTimestamp]

    public init(text: String, start: TimeInterval, end: TimeInterval, words: [WordTimestamp] = []) {
        self.text = text
        self.start = start
        self.end = end
        self.words = words
    }
}

/// Per-word timing. SoT did not lock the type shape; this matches WhisperKit's
/// internal `WordTiming` struct in spirit.
public struct WordTimestamp: Sendable, Equatable {
    public let word: String
    public let start: TimeInterval
    public let end: TimeInterval

    public init(word: String, start: TimeInterval, end: TimeInterval) {
        self.word = word
        self.start = start
        self.end = end
    }
}

/// Final transcription product handed back to callers. Named `Transcript`
/// (not `TranscriptionResult`) to avoid a name collision with WhisperKit's
/// own top-level `TranscriptionResult` struct, which would otherwise shadow
/// our type wherever `import WhisperKit` is in scope. `text` is a
/// space-joined concatenation of segment text — most consumers will iterate
/// `segments` directly to preserve timing.
public struct Transcript: Sendable, Equatable {
    public let segments: [TranscriptSegment]
    public let language: String
    public let duration: TimeInterval
    public let model: WhisperModel

    public init(
        segments: [TranscriptSegment],
        language: String,
        duration: TimeInterval,
        model: WhisperModel
    ) {
        self.segments = segments
        self.language = language
        self.duration = duration
        self.model = model
    }

    public var text: String {
        segments
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    public var allWords: [WordTimestamp] {
        segments.flatMap { $0.words }
    }
}
