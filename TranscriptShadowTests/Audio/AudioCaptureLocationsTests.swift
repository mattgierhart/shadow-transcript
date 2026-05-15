// @implements API-001 (EPIC-02b regression coverage)
import XCTest
@testable import TranscriptShadow

final class AudioCaptureLocationsTests: XCTestCase {

    func test_newRecordingURL_isUniqueAcrossRapidCalls() throws {
        // Use a fixed clock-like Date so the only entropy is the UUID suffix.
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        var seen = Set<URL>()
        for _ in 0..<200 {
            let url = try AudioCaptureLocations.newRecordingURL(date: date)
            XCTAssertFalse(seen.contains(url), "newRecordingURL must produce unique URLs even under same-millisecond calls")
            seen.insert(url)
        }
    }

    func test_newRecordingURL_includesFractionalSeconds() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000.123)
        let url = try AudioCaptureLocations.newRecordingURL(date: date)
        XCTAssertTrue(url.lastPathComponent.contains("."),
                      "filename should include a fractional-second component (millisecond precision)")
    }
}
