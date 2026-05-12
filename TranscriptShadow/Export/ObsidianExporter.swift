// @implements API-202, INT-001, BR-301, BR-302, FEA-005
import Foundation

/// File-system export of a `FormattedTranscript` into an Obsidian
/// vault. Pure I/O — composes YAML frontmatter from
/// `FormattedTranscript.metadata` + `speakerMap`, prepends to
/// `markdown`, writes atomically.
///
/// Returns the absolute URL of the written file so callers (eventually
/// `TranscriptStore.markExported`) can record it on the row.
public protocol ObsidianExporter: Sendable {
    func export(
        transcript: FormattedTranscript,
        title: String,
        date: Date,
        vaultPath: URL,
        subfolder: String?
    ) throws -> URL
}

public enum ObsidianExportError: Error, Equatable {
    case vaultPathNotADirectory(URL)
    case fileExists(URL)
    case writeFailed(path: String, underlying: String)
}

/// `@unchecked Sendable` is intentional: `FileManager` isn't formally
/// `Sendable` but Apple documents `FileManager.default` as thread-safe,
/// and both stored properties (`fileManager`, `overwriteExisting`) are
/// `let`-bound so the class has no mutable state. The protocol requires
/// `Sendable` so EPIC-07's `@MainActor` view models can dispatch
/// `export(...)` to a background task without crossing isolation
/// warnings. Same pattern as `PyannoteSidecarDiarizationService`.
public final class DefaultObsidianExporter: ObsidianExporter, @unchecked Sendable {
    private let fileManager: FileManager
    private let overwriteExisting: Bool

    public init(fileManager: FileManager = .default, overwriteExisting: Bool = false) {
        self.fileManager = fileManager
        self.overwriteExisting = overwriteExisting
    }

    public func export(
        transcript: FormattedTranscript,
        title: String,
        date: Date,
        vaultPath: URL,
        subfolder: String?
    ) throws -> URL {
        try ensureVaultDirectory(vaultPath)

        let destinationDirectory: URL
        if let sub = subfolder?.trimmingCharacters(in: .whitespaces), !sub.isEmpty {
            destinationDirectory = vaultPath.appendingPathComponent(sub, isDirectory: true)
            try fileManager.createDirectory(
                at: destinationDirectory,
                withIntermediateDirectories: true
            )
        } else {
            destinationDirectory = vaultPath
        }

        let filename = MarkdownFilenameSanitizer.makeFilename(date: date, title: title)
        let destination = destinationDirectory.appendingPathComponent(filename, isDirectory: false)

        if fileManager.fileExists(atPath: destination.path), !overwriteExisting {
            throw ObsidianExportError.fileExists(destination)
        }

        let body = renderDocument(transcript: transcript, title: title, date: date)
        do {
            try body.write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            throw ObsidianExportError.writeFailed(
                path: destination.path,
                underlying: "\(error)"
            )
        }
        return destination
    }

    // MARK: - Helpers

    private func ensureVaultDirectory(_ vaultPath: URL) throws {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: vaultPath.path, isDirectory: &isDirectory) else {
            // Allow creating the vault directory if it's missing — Obsidian
            // would normally already exist, but for first-launch
            // automation we don't want to gate on it.
            try fileManager.createDirectory(at: vaultPath, withIntermediateDirectories: true)
            return
        }
        if !isDirectory.boolValue {
            throw ObsidianExportError.vaultPathNotADirectory(vaultPath)
        }
    }

    /// Frontmatter shape per INT-001:
    /// ```
    /// ---
    /// date: 2026-03-11
    /// type: meeting-transcript
    /// duration: "45:30"
    /// speakers: ["Alice", "Bob"]
    /// source: transcript-shadow
    /// tags: [meeting, transcript]
    /// ---
    /// ```
    private func renderDocument(
        transcript: FormattedTranscript,
        title: String,
        date: Date
    ) -> String {
        let frontmatter = renderFrontmatter(
            transcript: transcript,
            title: title,
            date: date
        )
        return frontmatter + "\n\n" + transcript.markdown + "\n"
    }

    private func renderFrontmatter(
        transcript: FormattedTranscript,
        title: String,
        date: Date
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let dateString = formatter.string(from: date)

        let duration = formatDuration(transcript.metadata.durationSeconds)

        // Speaker names ordered by canonical key sort so the YAML is
        // stable across runs of the same input.
        let speakerNames = transcript.speakerMap
            .sorted { $0.key < $1.key }
            .map { $0.value }
        let speakersList = "[" + speakerNames.map(quoted).joined(separator: ", ") + "]"

        return """
        ---
        date: \(dateString)
        title: \(quoted(title))
        type: meeting-transcript
        duration: \(quoted(duration))
        speakers: \(speakersList)
        source: transcript-shadow
        tags: [meeting, transcript]
        ---
        """
    }

    /// YAML-safe quoting. Wraps in double quotes; escapes embedded `"`,
    /// `\`, `\n`, `\r`, and `\t` so user-typed titles or speaker names
    /// containing newlines or tabs can't break the frontmatter block.
    /// Sufficient for the well-defined values the formatter produces.
    private func quoted(_ raw: String) -> String {
        let escaped = raw
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
        return "\"\(escaped)\""
    }

    /// `MM:SS` for durations under an hour, `H:MM:SS` otherwise. The
    /// INT-001 example uses `"45:30"` so we follow that shape.
    private func formatDuration(_ seconds: Int) -> String {
        let total = max(0, seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}
