import Foundation
@testable import TranscriptShadow

/// In-code builders for EPIC-05 test inputs. Both `Transcript` and
/// `DiarizationResult` are pure Codable structs by the time the formatter
/// runs — JSON fixtures aren't necessary. Each builder returns a paired
/// `(Transcript, DiarizationResult)` whose timings are internally
/// consistent so alignment assertions are non-trivial.
enum TranscriptFixtures {
    /// Three-speaker, ~30-second conversation. Word timings are spaced so
    /// each word's midpoint falls cleanly inside the matching diarization
    /// segment.
    ///
    /// Layout (canonical IDs ordered by first appearance):
    ///   - SPEAKER_00: [0.0, 4.5)   says "hello there how are you today"
    ///   - SPEAKER_01: [5.0, 11.5)  says "doing well thanks for asking and you"
    ///   - SPEAKER_00: [12.0, 17.5) says "great just shipped a new feature"
    ///   - SPEAKER_02: [18.0, 25.0) says "nice work congratulations to the team"
    static func make3SpeakerFixture() -> (Transcript, DiarizationResult) {
        let segments: [(speaker: String, start: Double, end: Double, words: [(String, Double, Double)])] = [
            ("SPEAKER_00", 0.0, 4.5, [
                ("hello", 0.2, 0.6),
                ("there", 0.7, 1.1),
                ("how", 1.5, 1.8),
                ("are", 1.9, 2.1),
                ("you", 2.2, 2.5),
                ("today", 2.6, 3.2),
            ]),
            ("SPEAKER_01", 5.0, 11.5, [
                ("doing", 5.2, 5.6),
                ("well", 5.8, 6.2),
                ("thanks", 6.4, 6.9),
                ("for", 7.0, 7.2),
                ("asking", 7.3, 7.9),
                ("and", 8.5, 8.8),
                ("you", 9.0, 9.4),
            ]),
            ("SPEAKER_00", 12.0, 17.5, [
                ("great", 12.2, 12.7),
                ("just", 13.0, 13.3),
                ("shipped", 13.4, 13.9),
                ("a", 14.0, 14.1),
                ("new", 14.2, 14.5),
                ("feature", 14.6, 15.3),
            ]),
            ("SPEAKER_02", 18.0, 25.0, [
                ("nice", 18.3, 18.7),
                ("work", 18.8, 19.2),
                ("congratulations", 19.5, 20.4),
                ("to", 20.6, 20.8),
                ("the", 20.9, 21.1),
                ("team", 21.2, 21.7),
            ]),
        ]

        let transcriptSegments = segments.map { entry -> TranscriptSegment in
            let words = entry.words.map { WordTimestamp(word: $0.0, start: $0.1, end: $0.2) }
            let text = entry.words.map { $0.0 }.joined(separator: " ")
            return TranscriptSegment(text: text, start: entry.start, end: entry.end, words: words)
        }
        let transcript = Transcript(
            segments: transcriptSegments,
            language: "en",
            duration: 25.0,
            model: .baseEN
        )

        let speakerSegments = segments.map {
            SpeakerSegment(speaker: $0.speaker, start: $0.start, end: $0.end)
        }
        // Per-speaker totals
        let speakerTotals: [String: Double] = Dictionary(grouping: segments, by: { $0.speaker })
            .mapValues { entries in entries.reduce(0.0) { $0 + ($1.end - $1.start) } }
        let speakers = ["SPEAKER_00", "SPEAKER_01", "SPEAKER_02"].map {
            Speaker(id: $0, totalSeconds: speakerTotals[$0] ?? 0)
        }

        let diarization = DiarizationResult(
            version: DiarizationResult.supportedSchemaVersion,
            audio: AudioInfo(path: "/tmp/fixture.wav", durationSeconds: 25.0),
            model: ModelInfo(name: "pyannote/speaker-diarization-community-1", revision: "fixture"),
            speakers: speakers,
            segments: speakerSegments,
            overlappingSegments: [],
            elapsedSeconds: 0.1,
            warnings: []
        )

        return (transcript, diarization)
    }

    /// Single-speaker, ~10-second monologue. Both the transcript and
    /// diarization contain exactly one speaker — the happy path for the
    /// most common recording shape.
    static func make1SpeakerFixture() -> (Transcript, DiarizationResult) {
        let words: [(String, Double, Double)] = [
            ("recording", 0.5, 1.1),
            ("a", 1.2, 1.3),
            ("quick", 1.4, 1.8),
            ("note", 1.9, 2.3),
            ("to", 2.4, 2.5),
            ("myself", 2.6, 3.2),
        ]
        let timestamps = words.map { WordTimestamp(word: $0.0, start: $0.1, end: $0.2) }
        let text = words.map { $0.0 }.joined(separator: " ")
        let transcript = Transcript(
            segments: [TranscriptSegment(text: text, start: 0.0, end: 4.0, words: timestamps)],
            language: "en",
            duration: 10.0,
            model: .baseEN
        )

        let diarization = DiarizationResult(
            version: DiarizationResult.supportedSchemaVersion,
            audio: AudioInfo(path: "/tmp/mono.wav", durationSeconds: 10.0),
            model: ModelInfo(name: "pyannote/speaker-diarization-community-1", revision: "fixture"),
            speakers: [Speaker(id: "SPEAKER_00", totalSeconds: 4.0)],
            segments: [SpeakerSegment(speaker: "SPEAKER_00", start: 0.0, end: 4.0)],
            overlappingSegments: [],
            elapsedSeconds: 0.05,
            warnings: []
        )
        return (transcript, diarization)
    }

    /// Transcript with words but `DiarizationResult.segments == []`. Hits
    /// the zero-segment single-speaker fallback path.
    static func makeZeroSegmentFixture() -> (Transcript, DiarizationResult) {
        let words: [(String, Double, Double)] = [
            ("orphan", 0.1, 0.6),
            ("text", 0.7, 1.0),
        ]
        let timestamps = words.map { WordTimestamp(word: $0.0, start: $0.1, end: $0.2) }
        let transcript = Transcript(
            segments: [TranscriptSegment(
                text: "orphan text",
                start: 0.0,
                end: 1.5,
                words: timestamps
            )],
            language: "en",
            duration: 1.5,
            model: .baseEN
        )
        let diarization = DiarizationResult(
            version: DiarizationResult.supportedSchemaVersion,
            audio: AudioInfo(path: "/tmp/empty-segments.wav", durationSeconds: 1.5),
            model: ModelInfo(name: "pyannote/speaker-diarization-community-1", revision: "fixture"),
            speakers: [],
            segments: [],
            overlappingSegments: [],
            elapsedSeconds: 0.01,
            warnings: []
        )
        return (transcript, diarization)
    }

    /// Word whose midpoint falls inside SPEAKER_00's segment but whose end
    /// extends past the boundary into SPEAKER_01's segment. The aligner
    /// should attribute it by midpoint (SPEAKER_00) and emit a straddle
    /// warning.
    static func makeStraddlingWordFixture() -> (Transcript, DiarizationResult) {
        // Word [4.6, 5.4] — midpoint 5.0 sits in SPEAKER_00's segment
        // ([0.0, 5.0))? No — segment.end is 5.0 and the rule is start <=
        // mid < end, so 5.0 falls into SPEAKER_01. Adjust the word so the
        // midpoint is 4.9 (within SPEAKER_00 [0, 5.0)) but end at 5.4
        // crosses into SPEAKER_01 [5.0, 8.0).
        let words: [(String, Double, Double)] = [
            ("crossing", 4.4, 5.4),  // mid = 4.9 → SPEAKER_00; end = 5.4 → SPEAKER_01 (straddle)
            ("response", 5.5, 6.0),  // mid = 5.75 → SPEAKER_01 (clean)
        ]
        let timestamps = words.map { WordTimestamp(word: $0.0, start: $0.1, end: $0.2) }
        let transcript = Transcript(
            segments: [TranscriptSegment(
                text: "crossing response",
                start: 4.4,
                end: 6.0,
                words: timestamps
            )],
            language: "en",
            duration: 8.0,
            model: .baseEN
        )

        let segs = [
            SpeakerSegment(speaker: "SPEAKER_00", start: 0.0, end: 5.0),
            SpeakerSegment(speaker: "SPEAKER_01", start: 5.0, end: 8.0),
        ]
        let diarization = DiarizationResult(
            version: DiarizationResult.supportedSchemaVersion,
            audio: AudioInfo(path: "/tmp/straddle.wav", durationSeconds: 8.0),
            model: ModelInfo(name: "pyannote/speaker-diarization-community-1", revision: "fixture"),
            speakers: [
                Speaker(id: "SPEAKER_00", totalSeconds: 5.0),
                Speaker(id: "SPEAKER_01", totalSeconds: 3.0),
            ],
            segments: segs,
            overlappingSegments: [],
            elapsedSeconds: 0.02,
            warnings: []
        )
        return (transcript, diarization)
    }

    /// `JSONEncoder([.sortedKeys, .prettyPrinted])` output of
    /// `DefaultTranscriptFormatter().format(make3SpeakerFixture())`.
    /// Mirrors `sidecar/test_fixtures/formatted-golden-3spk.json` and
    /// locks the wire shape EPIC-06 storage / EPIC-07 UI / external
    /// consumers depend on. Update both the constant and the file
    /// together when an intentional contract change ships; bump the
    /// EPIC-06 storage version at the same time.
    static let expectedThreeSpeakerCodableJSON: String = #"""
{
  "markdown" : "**Speaker 1** [00:00:00]:\nhello there how are you today\n\n**Speaker 2** [00:00:05]:\ndoing well thanks for asking and you\n\n**Speaker 1** [00:00:12]:\ngreat just shipped a new feature\n\n**Speaker 3** [00:00:18]:\nnice work congratulations to the team",
  "metadata" : {
    "durationSeconds" : 25,
    "language" : "en",
    "model" : "openai_whisper-base.en",
    "speakerCount" : 3,
    "turnCount" : 4,
    "wordCount" : 25
  },
  "speakerMap" : {
    "SPEAKER_00" : "Speaker 1",
    "SPEAKER_01" : "Speaker 2",
    "SPEAKER_02" : "Speaker 3"
  },
  "turns" : [
    {
      "canonicalSpeaker" : "SPEAKER_00",
      "displayName" : "Speaker 1",
      "endSeconds" : 3.2,
      "startSeconds" : 0.2,
      "text" : "hello there how are you today"
    },
    {
      "canonicalSpeaker" : "SPEAKER_01",
      "displayName" : "Speaker 2",
      "endSeconds" : 9.4,
      "startSeconds" : 5.2,
      "text" : "doing well thanks for asking and you"
    },
    {
      "canonicalSpeaker" : "SPEAKER_00",
      "displayName" : "Speaker 1",
      "endSeconds" : 15.3,
      "startSeconds" : 12.2,
      "text" : "great just shipped a new feature"
    },
    {
      "canonicalSpeaker" : "SPEAKER_02",
      "displayName" : "Speaker 3",
      "endSeconds" : 21.7,
      "startSeconds" : 18.3,
      "text" : "nice work congratulations to the team"
    }
  ],
  "warnings" : [

  ]
}
"""#
}
