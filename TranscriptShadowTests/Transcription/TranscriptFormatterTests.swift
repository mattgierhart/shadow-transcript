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

    // MARK: - Public `turns` shape (EPIC-06 storage prerequisite)

    func test_format_turns_exposesPerTurnStructure() throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let result = try formatter.format(transcription: transcript, diarization: diarization)

        XCTAssertEqual(result.turns.count, 4)
        XCTAssertEqual(result.turns.map { $0.canonicalSpeaker },
                       ["SPEAKER_00", "SPEAKER_01", "SPEAKER_00", "SPEAKER_02"])
        XCTAssertEqual(result.turns.map { $0.displayName },
                       ["Speaker 1", "Speaker 2", "Speaker 1", "Speaker 3"])
        // First turn covers "hello there how are you today" — first word
        // starts at 0.2; last word "today" ends at 3.2.
        XCTAssertEqual(result.turns[0].startSeconds, 0.2, accuracy: 1e-6)
        XCTAssertEqual(result.turns[0].endSeconds, 3.2, accuracy: 1e-6)
        XCTAssertEqual(result.turns[0].text, "hello there how are you today")
    }

    func test_format_turns_renameOverridesPropagateToDisplayName() throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let result = try formatter.format(
            transcription: transcript,
            diarization: diarization,
            speakerNames: ["SPEAKER_00": "Alice"]
        )
        let aliceTurns = result.turns.filter { $0.canonicalSpeaker == "SPEAKER_00" }
        XCTAssertEqual(aliceTurns.count, 2)
        XCTAssertTrue(aliceTurns.allSatisfy { $0.displayName == "Alice" })
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

    // MARK: - Codex Gate P2 #5: explicit wire-shape lock (EPIC-06 storage handoff)

    /// Byte-for-byte assertion against
    /// `TranscriptFixtures.expectedThreeSpeakerCodableJSON` (mirrors
    /// `sidecar/test_fixtures/formatted-golden-3spk.json`). If this
    /// fails, EPIC-06 storage / EPIC-07 UI / external consumers are
    /// about to be silently surprised by a shape change — update the
    /// constant + the sidecar file together and bump the EPIC-06
    /// storage version. The Codable round-trip above protects round-trip
    /// equality; this test protects the wire format itself.
    func test_formattedTranscript_jsonShapeMatchesGolden_locksEPIC06Contract() throws {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let result = try formatter.format(transcription: transcript, diarization: diarization)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(result)
        guard let encoded = String(data: data, encoding: .utf8) else {
            XCTFail("encoder produced non-UTF8 data")
            return
        }

        XCTAssertEqual(
            encoded,
            TranscriptFixtures.expectedThreeSpeakerCodableJSON,
            "wire shape drift — update constant + sidecar/test_fixtures/formatted-golden-3spk.json together"
        )
    }

    // MARK: - Codex Gate P1 #4: long pause splits same-speaker turn

    /// Same-speaker tokens separated by silence longer than
    /// `turnSplitGapSeconds` (default 2.0s) must produce two distinct
    /// turns, not one. Before this fix, `groupIntoTurns` collapsed both
    /// tokens into one `TranscriptTurn` whose `endSeconds - startSeconds`
    /// covered non-speech time — downstream DBT-003 rows would report a
    /// segment longer than its actual speech content.
    func test_format_sameSpeakerLongPause_splitsIntoSeparateTurns() throws {
        let transcript = Transcript(
            segments: [
                TranscriptSegment(
                    text: "hello pause world",
                    start: 0.0, end: 6.0,
                    words: [
                        WordTimestamp(word: "hello", start: 0.0, end: 0.5),
                        // 5s of silence — well above the 2s default.
                        WordTimestamp(word: "world", start: 5.5, end: 6.0),
                    ]
                )
            ],
            language: "en",
            duration: 6.0,
            model: .baseEN
        )
        let diarization = DiarizationResult(
            version: DiarizationResult.supportedSchemaVersion,
            audio: AudioInfo(path: "/tmp/pause.wav", durationSeconds: 6.0),
            model: ModelInfo(name: "pyannote/speaker-diarization-community-1", revision: "test"),
            speakers: [Speaker(id: "SPEAKER_00", totalSeconds: 1.0)],
            segments: [SpeakerSegment(speaker: "SPEAKER_00", start: 0.0, end: 6.0)],
            overlappingSegments: [],
            elapsedSeconds: 0.01,
            warnings: []
        )

        let result = try formatter.format(transcription: transcript, diarization: diarization)

        XCTAssertEqual(result.turns.count, 2, "long pause must split same-speaker into two turns")
        XCTAssertEqual(result.turns[0].text, "hello")
        XCTAssertEqual(result.turns[1].text, "world")
        XCTAssertLessThanOrEqual(
            result.turns[0].endSeconds - result.turns[0].startSeconds, 1.0,
            "first turn must not absorb the silence before the second word"
        )
    }

    func test_format_sameSpeakerSmallGap_staysInOneTurn() throws {
        let transcript = Transcript(
            segments: [
                TranscriptSegment(
                    text: "hello world",
                    start: 0.0, end: 2.0,
                    words: [
                        WordTimestamp(word: "hello", start: 0.0, end: 0.5),
                        // 1s gap — below the 2s default.
                        WordTimestamp(word: "world", start: 1.5, end: 2.0),
                    ]
                )
            ],
            language: "en",
            duration: 2.0,
            model: .baseEN
        )
        let diarization = DiarizationResult(
            version: DiarizationResult.supportedSchemaVersion,
            audio: AudioInfo(path: "/tmp/short.wav", durationSeconds: 2.0),
            model: ModelInfo(name: "pyannote/speaker-diarization-community-1", revision: "test"),
            speakers: [Speaker(id: "SPEAKER_00", totalSeconds: 1.0)],
            segments: [SpeakerSegment(speaker: "SPEAKER_00", start: 0.0, end: 2.0)],
            overlappingSegments: [],
            elapsedSeconds: 0.01,
            warnings: []
        )

        let result = try formatter.format(transcription: transcript, diarization: diarization)

        XCTAssertEqual(result.turns.count, 1, "short same-speaker gap should not split")
        XCTAssertEqual(result.turns[0].text, "hello world")
    }
}
