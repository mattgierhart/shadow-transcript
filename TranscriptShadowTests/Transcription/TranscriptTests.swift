// @implements API-101
import XCTest
@testable import TranscriptShadow

final class TranscriptTests: XCTestCase {

    func test_text_concatenatesSegmentsWithSingleSpace() {
        let result = Transcript(
            segments: [
                TranscriptSegment(text: " hello ", start: 0.0, end: 1.0),
                TranscriptSegment(text: "world", start: 1.0, end: 2.0),
                TranscriptSegment(text: "   ", start: 2.0, end: 2.1) // whitespace-only segment dropped
            ],
            language: "en",
            duration: 2.1,
            model: .default
        )
        XCTAssertEqual(result.text, "hello world")
    }

    func test_allWords_concatenatesAcrossSegments() {
        let result = Transcript(
            segments: [
                TranscriptSegment(text: "alpha beta", start: 0.0, end: 1.0, words: [
                    WordTimestamp(word: "alpha", start: 0.0, end: 0.5),
                    WordTimestamp(word: "beta", start: 0.5, end: 1.0)
                ]),
                TranscriptSegment(text: "gamma", start: 1.0, end: 1.5, words: [
                    WordTimestamp(word: "gamma", start: 1.0, end: 1.5)
                ])
            ],
            language: "en",
            duration: 1.5,
            model: .default
        )
        XCTAssertEqual(result.allWords.count, 3)
        XCTAssertEqual(result.allWords.map(\.word), ["alpha", "beta", "gamma"])
    }
}
