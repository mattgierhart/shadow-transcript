// @implements BR-302
import XCTest
@testable import TranscriptShadow

final class MarkdownFilenameSanitizerTests: XCTestCase {

    func test_sanitize_passesThrough_safeText() {
        XCTAssertEqual(
            MarkdownFilenameSanitizer.sanitize("Weekly Standup"),
            "Weekly Standup"
        )
    }

    func test_sanitize_replacesDisallowedCharsWithSpace() {
        XCTAssertEqual(
            MarkdownFilenameSanitizer.sanitize("a/b\\c:d?e*f<g>h|i\"j"),
            "a b c d e f g h i j"
        )
    }

    func test_sanitize_collapsesWhitespace() {
        XCTAssertEqual(
            MarkdownFilenameSanitizer.sanitize("hello   \t  world"),
            "hello world"
        )
    }

    func test_sanitize_stripsControlCharacters() {
        let raw = "good\u{0000}bye\u{001F}"
        XCTAssertEqual(MarkdownFilenameSanitizer.sanitize(raw), "good bye")
    }

    func test_sanitize_trimsLeadingAndTrailingDotsAndWhitespace() {
        XCTAssertEqual(
            MarkdownFilenameSanitizer.sanitize("...   Hello  ...   "),
            "Hello"
        )
    }

    func test_sanitize_returnsUntitled_forEmptyAfterCleanup() {
        XCTAssertEqual(MarkdownFilenameSanitizer.sanitize(""), "Untitled")
        XCTAssertEqual(MarkdownFilenameSanitizer.sanitize("//::"), "Untitled")
    }

    func test_sanitize_capsAtMaxLength() {
        let long = String(repeating: "a", count: 300)
        let result = MarkdownFilenameSanitizer.sanitize(long, maxLength: 200)
        XCTAssertEqual(result.count, 200)
    }

    func test_sanitize_preservesUnicode() {
        XCTAssertEqual(
            MarkdownFilenameSanitizer.sanitize("café — résumé"),
            "café — résumé"
        )
    }

    func test_makeFilename_formatsAsDateTitleMd() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = Date(timeIntervalSince1970: 1_700_006_400)  // 2023-11-14 16:00 UTC
        XCTAssertEqual(
            MarkdownFilenameSanitizer.makeFilename(
                date: date,
                title: "Weekly: Standup",
                calendar: calendar
            ),
            "2023-11-14 Weekly Standup.md"
        )
    }
}
