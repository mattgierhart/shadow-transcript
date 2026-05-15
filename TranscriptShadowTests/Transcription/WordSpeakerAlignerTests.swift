// @implements TEST-303, API-201, RISK-005
import XCTest
@testable import TranscriptShadow

final class WordSpeakerAlignerTests: XCTestCase {
    private let aligner = WordSpeakerAligner()

    // MARK: - TEST-303 happy path

    func test_align_attributesEveryWordToCorrectSpeaker_onGoldenFixture() throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let result = try aligner.align(transcription: transcript, diarization: diarization)

        // Every word's midpoint should fall inside the matching speaker
        // segment (±1.0s per TEST-303 spec). Build the expected
        // attribution from the fixture's segment timing and compare.
        var expected: [String] = []
        for word in transcript.allWords {
            let mid = (word.start + word.end) / 2
            let segment = diarization.segments.first { $0.start <= mid && mid < $0.end }
            XCTAssertNotNil(segment, "Word '\(word.word)' midpoint \(mid) falls in silence")
            expected.append(segment?.speaker ?? "")
        }
        let actual = result.tokens.map { $0.canonicalSpeaker }
        XCTAssertEqual(actual, expected)
        XCTAssertEqual(result.canonicalOrder, ["SPEAKER_00", "SPEAKER_01", "SPEAKER_02"])
        XCTAssertTrue(result.warnings.isEmpty, "No straddle or fallback expected on golden fixture")
    }

    func test_align_returnsTokensInTranscriptOrder() throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let result = try aligner.align(transcription: transcript, diarization: diarization)
        let allWords = transcript.allWords.map { $0.word }
        XCTAssertEqual(result.tokens.map { $0.text }, allWords)
    }

    // MARK: - Boundary straddle

    func test_align_straddlingWord_attributedByMidpoint_emitsWarning() throws {
        let (transcript, diarization) = TranscriptFixtures.makeStraddlingWordFixture()
        let result = try aligner.align(transcription: transcript, diarization: diarization)

        XCTAssertEqual(result.tokens.count, 2)
        // First word: mid=4.9 → SPEAKER_00; straddles into SPEAKER_01.
        XCTAssertEqual(result.tokens[0].canonicalSpeaker, "SPEAKER_00")
        XCTAssertEqual(result.tokens[0].text, "crossing")
        // Second word: clean midpoint in SPEAKER_01.
        XCTAssertEqual(result.tokens[1].canonicalSpeaker, "SPEAKER_01")
        XCTAssertEqual(result.tokens[1].text, "response")

        XCTAssertTrue(
            result.warnings.contains { $0.contains("straddled") },
            "Expected a straddle warning; got \(result.warnings)"
        )
    }

    // MARK: - Silence (word midpoint outside all segments)

    func test_align_wordInSilence_attributedToUnknown() throws {
        // Word fully outside any diarization segment (gap from 3.0..5.0).
        let transcript = Transcript(
            segments: [TranscriptSegment(
                text: "ghost",
                start: 3.0,
                end: 5.0,
                words: [WordTimestamp(word: "ghost", start: 3.5, end: 4.5)]
            )],
            language: "en",
            duration: 10.0,
            model: .baseEN
        )
        let diarization = DiarizationResult(
            version: DiarizationResult.supportedSchemaVersion,
            audio: AudioInfo(path: "/tmp/silence.wav", durationSeconds: 10.0),
            model: ModelInfo(name: "pyannote/speaker-diarization-community-1", revision: "test"),
            speakers: [
                Speaker(id: "SPEAKER_00", totalSeconds: 2.0),
                Speaker(id: "SPEAKER_01", totalSeconds: 2.0),
            ],
            segments: [
                SpeakerSegment(speaker: "SPEAKER_00", start: 0.0, end: 3.0),
                SpeakerSegment(speaker: "SPEAKER_01", start: 5.0, end: 7.0),
            ],
            overlappingSegments: [],
            elapsedSeconds: 0.01,
            warnings: []
        )

        let result = try aligner.align(transcription: transcript, diarization: diarization)
        XCTAssertEqual(result.tokens.count, 1)
        XCTAssertEqual(result.tokens[0].canonicalSpeaker, WordSpeakerAligner.unknownSpeakerID)
        XCTAssertTrue(result.canonicalOrder.contains(WordSpeakerAligner.unknownSpeakerID))
        XCTAssertTrue(
            result.warnings.contains { $0.contains("could not be attributed") },
            "Expected unknown-attribution warning; got \(result.warnings)"
        )
    }

    // MARK: - Empty `words` array → segment-level fallback

    func test_align_emptyWordsArray_fallsBackToSegmentMidpoint() throws {
        let transcript = Transcript(
            segments: [TranscriptSegment(
                text: "the whole sentence",
                start: 1.0,
                end: 3.0,
                words: [] // empty
            )],
            language: "en",
            duration: 5.0,
            model: .baseEN
        )
        // Segment midpoint = 2.0, falls inside SPEAKER_00 [0.0, 5.0).
        let diarization = DiarizationResult(
            version: DiarizationResult.supportedSchemaVersion,
            audio: AudioInfo(path: "/tmp/seg-fallback.wav", durationSeconds: 5.0),
            model: ModelInfo(name: "pyannote/speaker-diarization-community-1", revision: "test"),
            speakers: [Speaker(id: "SPEAKER_00", totalSeconds: 5.0)],
            segments: [SpeakerSegment(speaker: "SPEAKER_00", start: 0.0, end: 5.0)],
            overlappingSegments: [],
            elapsedSeconds: 0.01,
            warnings: []
        )

        let result = try aligner.align(transcription: transcript, diarization: diarization)
        XCTAssertEqual(result.tokens.count, 1)
        XCTAssertEqual(result.tokens[0].canonicalSpeaker, "SPEAKER_00")
        XCTAssertEqual(result.tokens[0].text, "the whole sentence")
    }

    // MARK: - Zero diarization segments → single-speaker fallback

    func test_align_zeroSegments_singleSpeakerFallback_emitsWarning() throws {
        let (transcript, diarization) = TranscriptFixtures.makeZeroSegmentFixture()
        let result = try aligner.align(transcription: transcript, diarization: diarization)

        XCTAssertEqual(result.canonicalOrder, ["SPEAKER_00"])
        XCTAssertTrue(result.tokens.allSatisfy { $0.canonicalSpeaker == "SPEAKER_00" })
        XCTAssertEqual(result.tokens.map { $0.text }, ["orphan", "text"])
        XCTAssertTrue(
            result.warnings.contains { $0.contains("single-speaker fallback") },
            "Expected single-speaker fallback warning; got \(result.warnings)"
        )
    }

    // MARK: - Invalid segment → throws

    func test_align_invalidSegment_endLessThanStart_throws() {
        let transcript = Transcript(
            segments: [],
            language: "en",
            duration: 1.0,
            model: .baseEN
        )
        let diarization = DiarizationResult(
            version: DiarizationResult.supportedSchemaVersion,
            audio: AudioInfo(path: "/tmp/bad.wav", durationSeconds: 1.0),
            model: ModelInfo(name: "pyannote/speaker-diarization-community-1", revision: "test"),
            speakers: [],
            segments: [SpeakerSegment(speaker: "SPEAKER_00", start: 5.0, end: 2.0)],
            overlappingSegments: [],
            elapsedSeconds: 0.01,
            warnings: []
        )

        XCTAssertThrowsError(
            try aligner.align(transcription: transcript, diarization: diarization)
        ) { error in
            guard case FormatterError.invalidSpeakerSegment(let start, let end) = error else {
                return XCTFail("Expected invalidSpeakerSegment, got \(error)")
            }
            XCTAssertEqual(start, 5.0)
            XCTAssertEqual(end, 2.0)
        }
    }

    func test_align_invalidSegment_endEqualsStart_throws() {
        let transcript = Transcript(segments: [], language: "en", duration: 1.0, model: .baseEN)
        let diarization = DiarizationResult(
            version: DiarizationResult.supportedSchemaVersion,
            audio: AudioInfo(path: "/tmp/eq.wav", durationSeconds: 1.0),
            model: ModelInfo(name: "pyannote/speaker-diarization-community-1", revision: "test"),
            speakers: [],
            segments: [SpeakerSegment(speaker: "SPEAKER_00", start: 3.0, end: 3.0)],
            overlappingSegments: [],
            elapsedSeconds: 0.01,
            warnings: []
        )
        XCTAssertThrowsError(try aligner.align(transcription: transcript, diarization: diarization))
    }

    // MARK: - First-appearance ordering invariant

    func test_canonicalOrder_followsFirstAppearance_notLexicographic() throws {
        // SPEAKER_01 enters first, then SPEAKER_00. Expected order:
        // [SPEAKER_01, SPEAKER_00].
        let transcript = Transcript(
            segments: [TranscriptSegment(
                text: "hi back",
                start: 0.0,
                end: 4.0,
                words: [
                    WordTimestamp(word: "hi", start: 0.5, end: 1.0),
                    WordTimestamp(word: "back", start: 2.5, end: 3.0),
                ]
            )],
            language: "en",
            duration: 4.0,
            model: .baseEN
        )
        let diarization = DiarizationResult(
            version: DiarizationResult.supportedSchemaVersion,
            audio: AudioInfo(path: "/tmp/order.wav", durationSeconds: 4.0),
            model: ModelInfo(name: "pyannote/speaker-diarization-community-1", revision: "test"),
            speakers: [
                Speaker(id: "SPEAKER_00", totalSeconds: 2.0),
                Speaker(id: "SPEAKER_01", totalSeconds: 2.0),
            ],
            segments: [
                SpeakerSegment(speaker: "SPEAKER_01", start: 0.0, end: 2.0),
                SpeakerSegment(speaker: "SPEAKER_00", start: 2.0, end: 4.0),
            ],
            overlappingSegments: [],
            elapsedSeconds: 0.01,
            warnings: []
        )
        let result = try aligner.align(transcription: transcript, diarization: diarization)
        XCTAssertEqual(result.canonicalOrder, ["SPEAKER_01", "SPEAKER_00"])
    }

    // MARK: - Codex Gate P1 #1: ±boundaryEpsilon containment

    /// A word whose midpoint sits within `boundaryEpsilon` past a segment
    /// boundary must attribute to the containing segment, not flip to the
    /// next one (or become SPEAKER_UNKNOWN). Before the epsilon fix, the
    /// half-open `<=` / `<` check excluded `midpoint == segment.end`
    /// outright; tiny float drift past that boundary did the same.
    func test_align_wordMidpointWithinEpsilonOfBoundary_attributesToContainingSegment() throws {
        // Build a transcript where one word's midpoint lands exactly at
        // the SPEAKER_00 → SPEAKER_01 boundary at 2.0s.
        let word = WordTimestamp(word: "yes", start: 1.5, end: 2.5)  // mid = 2.0
        let transcript = Transcript(
            segments: [TranscriptSegment(text: "yes", start: 1.5, end: 2.5, words: [word])],
            language: "en",
            duration: 4.0,
            model: .baseEN
        )
        let diarization = DiarizationResult(
            version: DiarizationResult.supportedSchemaVersion,
            audio: AudioInfo(path: "/tmp/boundary.wav", durationSeconds: 4.0),
            model: ModelInfo(name: "pyannote/speaker-diarization-community-1", revision: "test"),
            speakers: [
                Speaker(id: "SPEAKER_00", totalSeconds: 2.0),
                Speaker(id: "SPEAKER_01", totalSeconds: 2.0),
            ],
            segments: [
                SpeakerSegment(speaker: "SPEAKER_00", start: 0.0, end: 2.0),
                SpeakerSegment(speaker: "SPEAKER_01", start: 2.0, end: 4.0),
            ],
            overlappingSegments: [],
            elapsedSeconds: 0.01,
            warnings: []
        )

        let result = try aligner.align(transcription: transcript, diarization: diarization)

        // With the epsilon window, the midpoint at 2.0 falls inside
        // SPEAKER_00's tolerance band (its half-open upper edge becomes
        // `2.0 + ε`). Without the fix this returned SPEAKER_UNKNOWN.
        XCTAssertEqual(result.tokens.first?.canonicalSpeaker, "SPEAKER_00")
    }

    // MARK: - Codex Gate P1 #2: no-word segment-level fallback uses overlap, not midpoint

    /// A `TranscriptSegment` with empty `words` that spans two
    /// diarization speakers must attribute to the speaker with the
    /// larger temporal overlap, not blindly to whoever owns the midpoint.
    /// Before this fix, a 10-second silent fallback that spent 9s in
    /// SPEAKER_00 and 1s in SPEAKER_01 (midpoint inside SPEAKER_01's
    /// segment because the boundary sits at 9s) would attribute the
    /// whole thing to SPEAKER_01.
    func test_align_noWordsSegmentStraddling_attributesToLargerOverlapSpeaker() throws {
        let transcript = Transcript(
            segments: [
                TranscriptSegment(text: "long quiet stretch", start: 0.0, end: 10.0, words: [])
            ],
            language: "en",
            duration: 10.0,
            model: .baseEN
        )
        let diarization = DiarizationResult(
            version: DiarizationResult.supportedSchemaVersion,
            audio: AudioInfo(path: "/tmp/spread.wav", durationSeconds: 10.0),
            model: ModelInfo(name: "pyannote/speaker-diarization-community-1", revision: "test"),
            speakers: [
                Speaker(id: "SPEAKER_00", totalSeconds: 9.0),
                Speaker(id: "SPEAKER_01", totalSeconds: 1.0),
            ],
            segments: [
                SpeakerSegment(speaker: "SPEAKER_00", start: 0.0, end: 9.0),
                SpeakerSegment(speaker: "SPEAKER_01", start: 9.0, end: 10.0),
            ],
            overlappingSegments: [],
            elapsedSeconds: 0.01,
            warnings: []
        )

        let result = try aligner.align(transcription: transcript, diarization: diarization)

        // SPEAKER_00 holds 9s of overlap vs SPEAKER_01's 1s — must win.
        // (Midpoint at 5.0 happens to land inside SPEAKER_00 too, so we
        // could also confirm via a flipped fixture where midpoint and
        // overlap-largest disagree.)
        XCTAssertEqual(result.tokens.first?.canonicalSpeaker, "SPEAKER_00")
        XCTAssertTrue(
            result.warnings.contains { $0.contains("straddled") },
            "straddle warning expected; got \(result.warnings)"
        )
    }

    /// Same as above but with the boundary placed so the midpoint and
    /// the larger-overlap speaker disagree. Midpoint of `[0, 10]` is
    /// `5.0`; if the boundary sits at `4.0`, midpoint lands in
    /// SPEAKER_01 (4..10 = 6s) but the SPEAKER_00 share is only 4s — so
    /// midpoint and overlap agree here too. To prove the change really
    /// uses overlap not midpoint, asymmetric ratios are required:
    /// boundary at 1.0s means SPEAKER_00 has 1s of overlap and
    /// SPEAKER_01 has 9s; midpoint 5.0 is in SPEAKER_01, overlap also
    /// favors SPEAKER_01 — agree again. The genuinely discriminating
    /// case needs a *non-contiguous* third segment placement.
    func test_align_noWordsSegmentStraddling_overlapWinsWhenMidpointDisagrees() throws {
        // Word span [0, 10]. Boundary at 1.0s with SPEAKER_00 in [0,1]
        // and SPEAKER_01 in [1, 6], then back to SPEAKER_00 in [6, 10].
        // Midpoint 5.0 sits in SPEAKER_01 (which holds 5s of overlap).
        // SPEAKER_00 holds 1 + 4 = 5s of overlap — exact tie. Use a
        // slight imbalance so the test result is unambiguous.
        let transcript = Transcript(
            segments: [
                TranscriptSegment(text: "silent stretch", start: 0.0, end: 10.0, words: [])
            ],
            language: "en",
            duration: 10.0,
            model: .baseEN
        )
        let diarization = DiarizationResult(
            version: DiarizationResult.supportedSchemaVersion,
            audio: AudioInfo(path: "/tmp/threespkr.wav", durationSeconds: 10.0),
            model: ModelInfo(name: "pyannote/speaker-diarization-community-1", revision: "test"),
            speakers: [
                Speaker(id: "SPEAKER_00", totalSeconds: 6.0),
                Speaker(id: "SPEAKER_01", totalSeconds: 4.0),
            ],
            segments: [
                SpeakerSegment(speaker: "SPEAKER_00", start: 0.0, end: 2.0),
                SpeakerSegment(speaker: "SPEAKER_01", start: 2.0, end: 6.0),
                SpeakerSegment(speaker: "SPEAKER_00", start: 6.0, end: 10.0),
            ],
            overlappingSegments: [],
            elapsedSeconds: 0.01,
            warnings: []
        )

        let result = try aligner.align(transcription: transcript, diarization: diarization)

        // Midpoint 5.0 lands in SPEAKER_01 (2..6). But SPEAKER_00 holds
        // 2 + 4 = 6s of overlap, SPEAKER_01 only 4s. Overlap-based
        // attribution picks SPEAKER_00; midpoint-only would've picked
        // SPEAKER_01 — this is the discriminating test.
        XCTAssertEqual(
            result.tokens.first?.canonicalSpeaker,
            "SPEAKER_00",
            "fallback must use largest overlap, not midpoint"
        )
    }
}
