// @implements BR-302
import Foundation

/// Produces an Obsidian-safe filename body (no extension).
///
/// Per BR-302, exported files MUST work within Obsidian's conventions.
/// Obsidian (and the underlying filesystem) reject these characters in
/// filenames: `/`, `\`, `:`, `?`, `*`, `<`, `>`, `|`, `"`, plus control
/// characters and the path components `.` / `..`. We replace each
/// rejected character with a single space, collapse runs of whitespace,
/// trim trailing dots (Windows-Mac compatibility), and cap length at
/// 200 chars to stay below macOS's 255-byte filename limit even when
/// extended grapheme clusters get encoded.
public enum MarkdownFilenameSanitizer {
    private static let disallowed: CharacterSet = {
        var set = CharacterSet(charactersIn: "/\\:?*<>|\"")
        set.formUnion(.controlCharacters)
        return set
    }()

    public static func sanitize(_ raw: String, maxLength: Int = 200) -> String {
        // Replace disallowed chars with a space.
        let mapped = String(raw.unicodeScalars.map { scalar in
            disallowed.contains(scalar) ? Character(" ") : Character(scalar)
        })

        // Collapse whitespace runs.
        let collapsed = mapped
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")

        // Trim leading/trailing dots and whitespace (Windows compat).
        var trimmed = collapsed.trimmingCharacters(
            in: CharacterSet(charactersIn: ". \t\n")
        )

        if trimmed.isEmpty {
            trimmed = "Untitled"
        }

        // Cap length (UTF-8 byte budget on macOS is 255; keep margin).
        if trimmed.count > maxLength {
            trimmed = String(trimmed.prefix(maxLength)).trimmingCharacters(
                in: CharacterSet(charactersIn: ". \t\n")
            )
        }

        return trimmed
    }

    /// `YYYY-MM-DD Title.md` per INT-001.
    public static func makeFilename(date: Date, title: String, calendar: Calendar = .init(identifier: .gregorian)) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        let datePart = formatter.string(from: date)
        let titlePart = sanitize(title)
        return "\(datePart) \(titlePart).md"
    }
}
