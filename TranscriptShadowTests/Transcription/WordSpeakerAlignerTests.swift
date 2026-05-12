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
}
