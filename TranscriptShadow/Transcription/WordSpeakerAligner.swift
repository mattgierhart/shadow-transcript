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
    /// Token end time (seconds from audio start).
    let end: TimeInterval
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

    /// Half-window applied to every speaker-segment containment check.
    /// Pyannote serializes segment boundaries to 3 decimal places (1ms),
    /// and word timings from WhisperKit can drift by similar amounts when
    /// re-serialized. A strict `start <= t < end` check therefore lets a
    /// word whose midpoint lands a few microseconds past a boundary flip
    /// to the next speaker (or to SPEAKER_UNKNOWN) instead of being
    /// treated as the intended boundary case (Codex Gate, 2026-05-15).
    static let boundaryEpsilon: TimeInterval = 0.001

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
                // Segment-level fallback: a WhisperKit segment that
                // didn't emit per-word timings can span multiple
                // diarization speakers. Midpoint-only attribution would
                // silently assign the whole segment to one of them.
                // Use largest-temporal-overlap instead so a no-words
                // segment that straddles two speakers lands with the
                // speaker who actually spoke most of it (Codex Gate
                // P1 #2, 2026-05-15). Straddle still gets surfaced via
                // the warning.
                let attribution = attributeByOverlap(
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
                        start: segment.start,
                        end: segment.end
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
                        start: word.start,
                        end: word.end
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
        guard let containing = segments.first(where: { contains($0, time: midpoint) }) else {
            return Attribution(canonicalSpeaker: Self.unknownSpeakerID, straddled: false)
        }

        let startSegment = segments.first { contains($0, time: wordStart) }
        let endSegment = segments.first { contains($0, time: wordEnd) }
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

    /// Largest-total-overlap attribution. Used for `segment.words.isEmpty`
    /// fallback where a single token covers the whole `TranscriptSegment`
    /// and may span multiple diarization speakers — possibly via several
    /// non-contiguous segments per speaker. Aggregates overlap *per
    /// speaker* before picking the winner, so a speaker spread across
    /// two short segments outranks a speaker with one merely-larger
    /// single segment. Reports `straddled = true` whenever any other
    /// speaker also had non-zero overlap with the span.
    private func attributeByOverlap(
        wordStart: TimeInterval,
        wordEnd: TimeInterval,
        segments: [SpeakerSegment]
    ) -> Attribution {
        var totals: [String: TimeInterval] = [:]
        for segment in segments {
            let overlap = max(0, min(wordEnd, segment.end) - max(wordStart, segment.start))
            guard overlap > 0 else { continue }
            totals[segment.speaker, default: 0] += overlap
        }
        guard let winner = totals.max(by: { $0.value < $1.value }) else {
            return Attribution(canonicalSpeaker: Self.unknownSpeakerID, straddled: false)
        }
        let straddled = totals.count > 1
        return Attribution(canonicalSpeaker: winner.key, straddled: straddled)
    }

    /// Half-open containment with a ±`boundaryEpsilon` window on both
    /// sides — `segment.start - ε <= time < segment.end + ε`. Used at
    /// every word-vs-segment boundary check.
    private func contains(_ segment: SpeakerSegment, time: TimeInterval) -> Bool {
        let lower = segment.start - Self.boundaryEpsilon
        let upper = segment.end + Self.boundaryEpsilon
        return time >= lower && time < upper
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
                        start: segment.start,
                        end: segment.end
                    ))
                }
            } else {
                for word in segment.words {
                    let trimmed = word.word.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        tokens.append(AlignedToken(
                            canonicalSpeaker: canonical,
                            text: trimmed,
                            start: word.start,
                            end: word.end
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
