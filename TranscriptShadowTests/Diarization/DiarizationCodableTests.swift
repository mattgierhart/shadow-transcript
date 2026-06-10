// @implements TEST-201, API-102, INT-102
import XCTest
@testable import TranscriptShadow

/// TEST-201 (Swift half) — the Codable types must decode the EPIC-04a
/// golden fixture without modification. This is the cross-language
/// contract test: `sidecar/test_fixtures/golden-3spk.json` is byte-
/// identical to what the Python emitter produces.
final class DiarizationCodableTests: XCTestCase {
    func testDecodesGolden3SpkFixture() throws {
        let url = try Self.fixtureURL(named: "golden-3spk.json")
        let data = try Data(contentsOf: url)
        let result = try JSONDecoder().decode(DiarizationResult.self, from: data)

        XCTAssertEqual(result.version, "1.0")
        XCTAssertEqual(result.model.name, "pyannote/speaker-diarization-community-1")

        XCTAssertEqual(result.speakers.count, 3)
        XCTAssertEqual(Set(result.speakers.map(\.id)),
                       Set(["SPEAKER_00", "SPEAKER_01", "SPEAKER_02"]))

        XCTAssertEqual(result.segments.count, 6)
        XCTAssertFalse(result.overlappingSegments.isEmpty)

        XCTAssertEqual(result.audio.durationSeconds, 60.0)
        XCTAssertEqual(result.elapsedSeconds, 8.5)
        XCTAssertTrue(result.warnings.isEmpty)
    }

    func testDecodesGolden1SpkFixture() throws {
        let url = try Self.fixtureURL(named: "golden-1spk.json")
        let data = try Data(contentsOf: url)
        let result = try JSONDecoder().decode(DiarizationResult.self, from: data)

        XCTAssertEqual(result.speakers.count, 1)
        XCTAssertEqual(result.speakers.first?.id, "SPEAKER_00")
        XCTAssertTrue(result.segments.allSatisfy { $0.speaker == "SPEAKER_00" })
    }

    func testRoundTripsBackToJSON() throws {
        let url = try Self.fixtureURL(named: "golden-3spk.json")
        let original = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(DiarizationResult.self, from: original)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let reEncoded = try encoder.encode(decoded)
        let reDecoded = try JSONDecoder().decode(DiarizationResult.self, from: reEncoded)

        XCTAssertEqual(decoded, reDecoded, "Codable round-trip lost data")
    }

    func testEveryFixtureSegmentIsWellOrdered() throws {
        let url = try Self.fixtureURL(named: "golden-3spk.json")
        let data = try Data(contentsOf: url)
        let result = try JSONDecoder().decode(DiarizationResult.self, from: data)

        for seg in result.segments {
            XCTAssertGreaterThan(seg.end, seg.start, "bad segment: \(seg)")
        }
        for seg in result.overlappingSegments {
            XCTAssertGreaterThan(seg.end, seg.start, "bad overlapping: \(seg)")
        }
    }

    func testSpeakerTotalsConsistentWithSegments() throws {
        let url = try Self.fixtureURL(named: "golden-3spk.json")
        let data = try Data(contentsOf: url)
        let result = try JSONDecoder().decode(DiarizationResult.self, from: data)

        let computed = Dictionary(grouping: result.segments, by: { $0.speaker })
            .mapValues { segs in segs.reduce(0.0) { $0 + $1.duration } }

        for speaker in result.speakers {
            let expected = computed[speaker.id] ?? 0
            XCTAssertEqual(
                speaker.totalSeconds,
                expected,
                accuracy: 0.001,
                "speaker \(speaker.id) total mismatch"
            )
        }
    }

    // MARK: - Fixture loading

    private static func fixtureURL(named name: String) throws -> URL {
        // Resolve from the test bundle (fixtures are copied in via the
        // TranscriptShadowTests `resources` build phase in project.yml).
        // Reading from the source tree via #filePath hangs when the repo
        // lives under an iCloud-synced ~/Documents: CloudDocs mediates the
        // open() syscall and stalls for the freshly-built app binary. The
        // .xctest bundle lives in DerivedData (~/Library), which is local.
        let bundle = Bundle(for: DiarizationCodableTests.self)
        let resource = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        guard let url = bundle.url(forResource: resource, withExtension: ext) else {
            throw NSError(
                domain: "DiarizationCodableTests",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "fixture \(name) not found in test bundle \(bundle.bundlePath)"]
            )
        }
        return url
    }
}
