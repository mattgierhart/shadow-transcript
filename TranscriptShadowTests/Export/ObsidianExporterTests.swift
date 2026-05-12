// @implements TEST-401, TEST-402, API-202, INT-001, BR-302
import XCTest
@testable import TranscriptShadow

final class ObsidianExporterTests: XCTestCase {
    private var vaultRoot: URL!
    private let fixedDate = Date(timeIntervalSince1970: 1_700_006_400)
    // 2023-11-15 00:00:00 UTC — date string `2023-11-15`.

    override func setUpWithError() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("obsidian-vault-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        vaultRoot = tmp
        addTeardownBlock {
            try? FileManager.default.removeItem(at: tmp)
        }
    }

    // MARK: - TEST-401: Valid markdown file written

    func test_export_writesMarkdownFile_atDateTitlePath() throws {
        let exporter = DefaultObsidianExporter()
        let formatted = try makeFormatted()
        let url = try exporter.export(
            transcript: formatted,
            title: "Weekly Standup",
            date: fixedDate,
            vaultPath: vaultRoot,
            subfolder: "Meetings"
        )

        XCTAssertEqual(url.lastPathComponent, "2023-11-15 Weekly Standup.md")
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, "Meetings")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let body = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(body.hasPrefix("---\n"))
        XCTAssertTrue(body.contains(formatted.markdown))
        XCTAssertTrue(body.hasSuffix("\n"))
    }

    func test_export_createsSubfolder_whenMissing() throws {
        let exporter = DefaultObsidianExporter()
        let formatted = try makeFormatted()
        _ = try exporter.export(
            transcript: formatted,
            title: "Weekly",
            date: fixedDate,
            vaultPath: vaultRoot,
            subfolder: "Daily/Meetings"
        )
        let nested = vaultRoot.appendingPathComponent("Daily/Meetings", isDirectory: true)
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: nested.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }

    func test_export_writesToVaultRoot_whenSubfolderNilOrEmpty() throws {
        let exporter = DefaultObsidianExporter()
        let formatted = try makeFormatted()
        let url = try exporter.export(
            transcript: formatted,
            title: "RootLevel",
            date: fixedDate,
            vaultPath: vaultRoot,
            subfolder: nil
        )
        XCTAssertEqual(url.deletingLastPathComponent().path, vaultRoot.path)
    }

    func test_export_throwsFileExists_whenDestinationOccupied() throws {
        let exporter = DefaultObsidianExporter()
        let formatted = try makeFormatted()
        let first = try exporter.export(
            transcript: formatted,
            title: "Dup",
            date: fixedDate,
            vaultPath: vaultRoot,
            subfolder: nil
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: first.path))
        do {
            _ = try exporter.export(
                transcript: formatted,
                title: "Dup",
                date: fixedDate,
                vaultPath: vaultRoot,
                subfolder: nil
            )
            XCTFail("expected throw")
        } catch ObsidianExportError.fileExists {
            // pass
        }
    }

    func test_export_overwriteFlag_replacesExisting() throws {
        let exporter = DefaultObsidianExporter(overwriteExisting: true)
        let formatted = try makeFormatted()
        _ = try exporter.export(
            transcript: formatted,
            title: "Dup",
            date: fixedDate,
            vaultPath: vaultRoot,
            subfolder: nil
        )
        XCTAssertNoThrow(try exporter.export(
            transcript: formatted,
            title: "Dup",
            date: fixedDate,
            vaultPath: vaultRoot,
            subfolder: nil
        ))
    }

    func test_export_throwsNotADirectory_whenVaultPathIsFile() throws {
        let filePath = vaultRoot.appendingPathComponent("not-a-dir.txt", isDirectory: false)
        try Data("x".utf8).write(to: filePath)
        let exporter = DefaultObsidianExporter()
        let formatted = try makeFormatted()
        do {
            _ = try exporter.export(
                transcript: formatted,
                title: "x",
                date: fixedDate,
                vaultPath: filePath,
                subfolder: nil
            )
            XCTFail("expected throw")
        } catch ObsidianExportError.vaultPathNotADirectory {
            // pass
        }
    }

    // MARK: - TEST-402: Frontmatter is valid YAML

    func test_export_frontmatterContainsAllRequiredKeys() throws {
        let exporter = DefaultObsidianExporter()
        let formatted = try makeFormatted()
        let url = try exporter.export(
            transcript: formatted,
            title: "Weekly Standup",
            date: fixedDate,
            vaultPath: vaultRoot,
            subfolder: nil
        )
        let body = try String(contentsOf: url, encoding: .utf8)
        let frontmatter = try Self.extractFrontmatter(body)

        XCTAssertTrue(frontmatter.contains("date: 2023-11-15"), "date key missing: \(frontmatter)")
        XCTAssertTrue(frontmatter.contains("type: meeting-transcript"))
        XCTAssertTrue(frontmatter.contains("source: transcript-shadow"))
        XCTAssertTrue(frontmatter.contains("tags: [meeting, transcript]"))
        XCTAssertTrue(frontmatter.contains("duration:"))
        XCTAssertTrue(frontmatter.contains("speakers:"))
        XCTAssertTrue(frontmatter.contains("title: \"Weekly Standup\""))
    }

    func test_export_durationFormat_matchesINT001Example() throws {
        // INT-001 shows `duration: "45:30"` (MM:SS).
        let exporter = DefaultObsidianExporter()
        let formatted = try makeFormatted()  // duration ~25s → "0:25"
        let url = try exporter.export(
            transcript: formatted,
            title: "x",
            date: fixedDate,
            vaultPath: vaultRoot,
            subfolder: nil
        )
        let body = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(body.contains("duration: \"0:25\""), "got: \(body)")
    }

    func test_export_titleWithNewlineIsEscaped() throws {
        let exporter = DefaultObsidianExporter()
        let formatted = try makeFormatted()
        let url = try exporter.export(
            transcript: formatted,
            title: "Sync\nQ&A",
            date: fixedDate,
            vaultPath: vaultRoot,
            subfolder: nil
        )
        let body = try String(contentsOf: url, encoding: .utf8)
        let frontmatter = try Self.extractFrontmatter(body)
        // Title must appear on a single line — the raw `\n` must be escaped.
        XCTAssertTrue(
            frontmatter.contains(#"title: "Sync\nQ&A""#),
            "Title newline must be escaped to keep YAML parsable: \(frontmatter)"
        )
        // Frontmatter must end on the same logical block (no spurious
        // closing `---` mid-document).
        XCTAssertEqual(
            body.components(separatedBy: "\n---\n").count,
            2,
            "Expected exactly one frontmatter close marker"
        )
    }

    func test_export_emptyMarkdownBody_writesFrontmatterOnly() throws {
        let exporter = DefaultObsidianExporter()
        let empty = FormattedTranscript(
            markdown: "",
            metadata: TranscriptMetadata(
                durationSeconds: 0,
                speakerCount: 0,
                language: "en",
                model: .baseEN,
                wordCount: 0,
                turnCount: 0
            ),
            speakerMap: [:],
            warnings: [],
            turns: []
        )
        let url = try exporter.export(
            transcript: empty,
            title: "Empty",
            date: fixedDate,
            vaultPath: vaultRoot,
            subfolder: nil
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let body = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(body.hasPrefix("---\n"))
        XCTAssertTrue(body.contains("type: meeting-transcript"))
    }

    func test_export_speakers_areYAMLEscapedQuoted() throws {
        let exporter = DefaultObsidianExporter()
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        let formatted = try DefaultTranscriptFormatter().format(
            transcription: transcript,
            diarization: diarization,
            speakerNames: ["SPEAKER_00": "Alice \"Quoted\""]
        )
        let url = try exporter.export(
            transcript: formatted,
            title: "x",
            date: fixedDate,
            vaultPath: vaultRoot,
            subfolder: nil
        )
        let body = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(
            body.contains(#""Alice \"Quoted\"""#),
            "Quoted-name YAML escape failed: \(body)"
        )
    }

    // MARK: - Helpers

    private func makeFormatted() throws -> FormattedTranscript {
        let (transcript, diarization) = TranscriptFixtures.make3SpeakerFixture()
        return try DefaultTranscriptFormatter().format(
            transcription: transcript,
            diarization: diarization
        )
    }

    /// Extract the text between the leading `---` and the matching
    /// closing `---`. Returns the body text in between.
    private static func extractFrontmatter(_ document: String) throws -> String {
        let lines = document.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.first == "---" else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "no opening ---"])
        }
        guard let closeIndex = lines.dropFirst().firstIndex(of: "---") else {
            throw NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "no closing ---"])
        }
        return lines[1..<closeIndex].joined(separator: "\n")
    }
}
