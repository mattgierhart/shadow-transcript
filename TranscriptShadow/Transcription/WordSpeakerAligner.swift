// @implements API-201, FEA-003, RISK-005
import Foundation

/// One aligned token in the formatter pipeline. Either a real WhisperKit
/// `WordTimestamp` attributed to a canonical speaker, or a segment-level
/// fallback when the upstream `TranscriptSegment` had no per-word
/// timings.
struct AlignedToken: Equatable {
    /// Canonical speaker ID (`SPEAKER_00`, `SPEAKER_UNKNOWN`, …).
    let canonicalSpeaker: String
    /// Display text — single word, or the whole segment when falling back.
    let text: String
    /// Token start time (seconds from audio start).
    let start: TimeInterval
}

/// Output of one alignment pass.
struct AlignmentResult: Equatable {
    let tokens: [AlignedToken]
    /// Canonical IDs in first-appearance order across the diarization
    /// segments. The formatter uses this order to assign 1-indexed
    /// `Speaker N` display names. `SPEAKER_UNKNOWN`, when present, is
    /// appended last.
    let canonicalOrder: [String]
    let warnings: [String]
}

/// Internal alignment helper for `DefaultTranscriptFormatter`. Pulled into
/// its own type so the RISK-005 surface (off-by-one at speaker
/// boundaries, word-without-segment fallback, zero-segments fallback) is
/// testable in isolation without going through markdown emission.
///
/// Algorithm: midpoint-greedy. For each word, `midpoint = (start + end) / 2`;
/// find the unique segment in `diarization.segments` where
/// `segment.start <= midpoint < segment.end`. No match → `SPEAKER_UNKNOWN`.
/// Boundary straddles (word.start in segment A, word.end in segment B)
/// keep the midpoint attribution but increment a `straddleCount` reported
/// as a warning at the end.
///
/// Uses `DiarizationResult.segments` (exclusive view) only.
/// `overlappingSegments` is deferred to a future EPIC.
struct WordSpeakerAligner {
    static let unknownSpeakerID = "SPEAKER_UNKNOWN"

    func align(
        transcription: Transcript,
        diarization: DiarizationResult
    ) throws -> AlignmentResult {
        try validateSegments(diarization.segments)

        // Zero-segment fallback: synthesize a single SPEAKER_00 turn for
        // every word so a single-speaker recording produces a clean output.
        if diarization.segments.isEmpty {
            return fallbackSingleSpeaker(transcription: transcription)
        }

        let canonicalOrder = firstAppearanceOrder(of: diarization.segments)
        var tokens: [AlignedToken] = []
        var straddleCount = 0
        var unknownUsed = false

        for segment in transcription.segments {
            if segment.words.isEmpty {
                // Segment-level fallback: attribute the whole segment's
                // text by its midpoint.
                let mid = (segment.start + segment.end) / 2
                let attribution = attribute(
                    midpoint: mid,
                    wordStart: segment.start,
                    wordEnd: segment.end,
                    segments: diarization.segments
                )
                if attribution.canonicalSpeaker == Self.unknownSpeakerID {
                    unknownUsed = true
                }
                if attribution.straddled {
                    straddleCount += 1
                }
                let trimmed = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    tokens.append(AlignedToken(
                        canonicalSpeaker: attribution.canonicalSpeaker,
                        text: trimmed,
                        start: segment.start
                    ))
                }
                continue
            }

            for word in segment.words {
                let mid = (word.start + word.end) / 2
                let attribution = attribute(
                    midpoint: mid,
                    wordStart: word.start,
                    wordEnd: word.end,
                    segments: diarization.segments
                )
                if attribution.canonicalSpeaker == Self.unknownSpeakerID {
                    unknownUsed = true
                }
                if attribution.straddled {
                    straddleCount += 1
                }
                let trimmed = word.word.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    tokens.append(AlignedToken(
                        canonicalSpeaker: attribution.canonicalSpeaker,
                        text: trimmed,
                        start: word.start
                    ))
                }
            }
        }

        var orderedCanonical = canonicalOrder
        if unknownUsed && !orderedCanonical.contains(Self.unknownSpeakerID) {
            orderedCanonical.append(Self.unknownSpeakerID)
        }

        var warnings: [String] = []
        if straddleCount > 0 {
            warnings.append("\(straddleCount) words straddled speaker boundaries")
        }
        if unknownUsed {
            warnings.append("one or more words could not be attributed to a speaker")
        }

        return AlignmentResult(
            tokens: tokens,
            canonicalOrder: orderedCanonical,
            warnings: warnings
        )
    }

    // MARK: - Helpers

    private struct Attribution {
        let canonicalSpeaker: String
        let straddled: Bool
    }

    private func attribute(
        midpoint: TimeInterval,
        wordStart: TimeInterval,
        wordEnd: TimeInterval,
        segments: [SpeakerSegment]
    ) -> Attribution {
        guard let containing = segments.first(where: { segment in
            segment.start <= midpoint && midpoint < segment.end
        }) else {
            return Attribution(canonicalSpeaker: Self.unknownSpeakerID, straddled: false)
        }

        let startSegment = segments.first { $0.start <= wordStart && wordStart < $0.end }
        let endSegment = segments.first { $0.start <= wordEnd && wordEnd < $0.end }
        let straddled: Bool
        if let s = startSegment, let e = endSegment {
            straddled = s.speaker != e.speaker
        } else {
            // One end fell outside any segment but the midpoint didn't —
            // still counts as a boundary case worth surfacing.
            straddled = (startSegment == nil) != (endSegment == nil)
        }

        return Attribution(canonicalSpeaker: containing.speaker, straddled: straddled)
    }

    private func firstAppearanceOrder(of segments: [SpeakerSegment]) -> [String] {
        var seen = Set<String>()
        var order: [String] = []
        for segment in segments {
            if seen.insert(segment.speaker).inserted {
                order.append(segment.speaker)
            }
        }
        return order
    }

    private func validateSegments(_ segments: [SpeakerSegment]) throws {
        for segment in segments where segment.end <= segment.start {
            throw FormatterError.invalidSpeakerSegment(
                start: segment.start,
                end: segment.end
            )
        }
    }

    private func fallbackSingleSpeaker(transcription: Transcript) -> AlignmentResult {
        let canonical = "SPEAKER_00"
        var tokens: [AlignedToken] = []
        for segment in transcription.segments {
            if segment.words.isEmpty {
                let trimmed = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    tokens.append(AlignedToken(
                        canonicalSpeaker: canonical,
                        text: trimmed,
                        start: segment.start
                    ))
                }
            } else {
                for word in segment.words {
                    let trimmed = word.word.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        tokens.append(AlignedToken(
                            canonicalSpeaker: canonical,
                            text: trimmed,
                            start: word.start
                        ))
                    }
                }
            }
        }
        return AlignmentResult(
            tokens: tokens,
            canonicalOrder: [canonical],
            warnings: ["no diarization segments; single-speaker fallback"]
        )
    }
}
