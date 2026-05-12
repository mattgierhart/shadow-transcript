// @implements TEST-301, TEST-302, API-201, BR-301, FEA-004
import XCTest
@testable import TranscriptShadow

final class TranscriptFormatterTests: XCTestCase {
    private let formatter = DefaultTranscriptFormatter()

    // MARK: - TEST-301: Speaker-Labeled Markdown

    func test_format_3SpeakerFixture_producesSpeakerLabeledMarkdown() throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let result = try formatter.format(transcription: transcript, diarization: diarization)

        let expected = """
        **Speaker 1** [00:00:00]:
        hello there how are you today

        **Speaker 2** [00:00:05]:
        doing well thanks for asking and you

        **Speaker 1** [00:00:12]:
        great just shipped a new feature

        **Speaker 3** [00:00:18]:
        nice work congratulations to the team
        """
        XCTAssertEqual(result.markdown, expected)
    }

    func test_format_speakerMap_uses1IndexedDefaultsByFirstAppearance() throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let result = try formatter.format(transcription: transcript, diarization: diarization)
        XCTAssertEqual(result.speakerMap, [
            "SPEAKER_00": "Speaker 1",
            "SPEAKER_01": "Speaker 2",
            "SPEAKER_02": "Speaker 3",
        ])
    }

    func test_format_metadata_populatesAllFields() throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let result = try formatter.format(transcription: transcript, diarization: diarization)

        XCTAssertEqual(result.metadata.durationSeconds, 25)
        XCTAssertEqual(result.metadata.speakerCount, 3)
        XCTAssertEqual(result.metadata.language, "en")
        XCTAssertEqual(result.metadata.model, .baseEN)
        XCTAssertEqual(result.metadata.wordCount, transcript.allWords.count)
        // 4 turns: SPEAKER_00, SPEAKER_01, SPEAKER_00, SPEAKER_02
        XCTAssertEqual(result.metadata.turnCount, 4)
    }

    func test_format_emitsTimestampsInHHMMSSFormat() throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let result = try formatter.format(transcription: transcript, diarization: diarization)
        // Each turn starts with `**...** [HH:MM:SS]:`
        let lines = result.markdown.split(separator: "\n", omittingEmptySubsequences: false)
        let headerLines = lines.filter { $0.hasPrefix("**") }
        XCTAssertEqual(headerLines.count, 4)
        let pattern = #"^\*\*[^*]+\*\* \[\d{2}:\d{2}:\d{2}\]:$"#
        for line in headerLines {
            XCTAssertNotNil(
                line.range(of: pattern, options: .regularExpression),
                "Header line '\(line)' does not match HH:MM:SS pattern"
            )
        }
    }

    func test_format_turnsSeparatedByBlankLine() throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let result = try formatter.format(transcription: transcript, diarization: diarization)
        // 4 turns → 3 blank-line separators → 4 turn-blocks of 2 lines each
        // joined by `\n\n` makes the full string have exactly `count - 1`
        // double-newline boundaries.
        let separated = result.markdown.components(separatedBy: "\n\n")
        XCTAssertEqual(separated.count, 4)
    }

    // MARK: - TEST-302: Speaker Rename Propagation

    func test_format_speakerNamesOverride_replacesDisplayLabels() throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let names = ["SPEAKER_00": "Alice", "SPEAKER_01": "Bob"]
        let result = try formatter.format(
            transcription: transcript,
            diarization: diarization,
            speakerNames: names
        )

        XCTAssertTrue(result.markdown.contains("**Alice**"))
        XCTAssertTrue(result.markdown.contains("**Bob**"))
        // SPEAKER_02 has no override → falls back to default. Default
        // numbering is by first-appearance excluding unknowns, so
        // SPEAKER_02 (third to appear) gets "Speaker 3".
        XCTAssertTrue(result.markdown.contains("**Speaker 3**"))
        XCTAssertFalse(result.markdown.contains("SPEAKER_00"))
        XCTAssertFalse(result.markdown.contains("SPEAKER_01"))

        XCTAssertEqual(result.speakerMap, [
            "SPEAKER_00": "Alice",
            "SPEAKER_01": "Bob",
            "SPEAKER_02": "Speaker 3",
        ])
    }

    func test_format_partialRename_preservesUnrenamedSpeakerDefaults() throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let result = try formatter.format(
            transcription: transcript,
            diarization: diarization,
            speakerNames: ["SPEAKER_01": "Bob"]
        )
        XCTAssertEqual(result.speakerMap["SPEAKER_00"], "Speaker 1")
        XCTAssertEqual(result.speakerMap["SPEAKER_01"], "Bob")
        XCTAssertEqual(result.speakerMap["SPEAKER_02"], "Speaker 3")
    }

    // MARK: - Warnings passthrough + single-speaker

    func test_format_singleSpeakerFixture_producesOneTurn_noWarnings() throws {
        let (transcript, diarization) = TranscriptFixtures.make1SpeakerFixture()
        let result = try formatter.format(transcription: transcript, diarization: diarization)

        XCTAssertEqual(result.metadata.turnCount, 1)
        XCTAssertEqual(result.metadata.speakerCount, 1)
        XCTAssertEqual(result.speakerMap, ["SPEAKER_00": "Speaker 1"])
        XCTAssertTrue(result.markdown.hasPrefix("**Speaker 1** [00:00:00]:"))
        XCTAssertTrue(result.warnings.isEmpty)
    }

    func test_format_zeroSegmentFixture_emitsFallbackWarning() throws {
        let (transcript, diarization) = TranscriptFixtures.makeZeroSegmentFixture()
        let result = try formatter.format(transcription: transcript, diarization: diarization)
        XCTAssertEqual(result.speakerMap, ["SPEAKER_00": "Speaker 1"])
        XCTAssertTrue(
            result.warnings.contains { $0.contains("single-speaker fallback") },
            "Expected fallback warning; got \(result.warnings)"
        )
    }

    func test_format_passesThroughDiarizationWarnings() throws {
        let (transcript, base) = TranscriptFixtures.make3SpeakerFixture()
        let upstream = DiarizationResult(
            version: base.version,
            audio: base.audio,
            model: base.model,
            speakers: base.speakers,
            segments: base.segments,
            overlappingSegments: base.overlappingSegments,
            elapsedSeconds: base.elapsedSeconds,
            warnings: ["upstream: clipped audio detected"]
        )
        let result = try formatter.format(transcription: transcript, diarization: upstream)
        XCTAssertTrue(result.warnings.contains("upstream: clipped audio detected"))
    }

    // MARK: - Codable round-trip (EPIC-06 storage guard)

    func test_formattedTranscript_codableRoundTrip_preservesAllFields() throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let original = try formatter.format(transcription: transcript, diarization: diarization)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(FormattedTranscript.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}
