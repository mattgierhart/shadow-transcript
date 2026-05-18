// @implements SCR-004, UJ-002, BR-301, API-201, DBT-002
// View-model for the SCR-004 transcript view. Loads `StoredTranscript`
// from `TranscriptStore.fetch(id:)`, projects it into a
// `TranscriptDisplayModel`, and writes through speaker renames via
// `TranscriptStore.updateSpeakerDisplayName(...)`.
//
// Demo IDs like "t1"..."t9" (non-UUID strings used by the Cmd+3 demo
// shortcut) bypass the fetch and surface the canned `.mock` display
// model unchanged — keeps the demo flow alive through Phase 3.

#if canImport(AppKit)
import AppKit
#endif
import Combine
import Foundation

@MainActor
final class TranscriptViewModel: ObservableObject {
    @Published var displayModel: TranscriptDisplayModel = .mock
    @Published var loadError: String?
    @Published var renameError: String?
    @Published var exportError: String?
    @Published var exportedURL: URL?
    @Published var isLoading: Bool = false

    private(set) var transcriptID: UUID?
    private(set) var stored: StoredTranscript?
    let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    /// Load a transcript by its public ID. Accepts the string form so the
    /// demo navigation (Cmd+3, IDs like "t1") works alongside real
    /// UUID-stringified IDs from `TranscriptStore.list`.
    func load(id: String) async {
        guard let uuid = UUID(uuidString: id) else {
            transcriptID = nil
            displayModel = .mock
            loadError = nil
            return
        }
        await load(id: uuid)
    }

    func load(id: UUID) async {
        transcriptID = id
        isLoading = true
        defer { isLoading = false }
        do {
            guard let fetched = try await env.transcripts.fetch(id: id) else {
                loadError = "Transcript not found"
                stored = nil
                return
            }
            stored = fetched
            displayModel = Self.makeDisplayModel(from: fetched)
            loadError = nil
            exportedURL = fetched.exportedPath
        } catch {
            loadError = "\(error)"
        }
    }

    /// Rename a single speaker by canonical key. Refuses the rename if
    /// another speaker on the same transcript already uses that display
    /// name. On success the display model is re-projected so every turn
    /// referencing the speaker updates instantly.
    func renameSpeaker(canonical: String, to newName: String) async {
        renameError = nil
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            renameError = "Name can't be blank."
            return
        }
        guard let transcriptID else { return }

        // Collision: another speaker (different canonical key) already
        // uses this display name on this transcript.
        let sourceCanonical = canonical
        let collides = displayModel.speakers.contains(where: { speaker in
            speaker.canonicalKey != sourceCanonical && speaker.name.caseInsensitiveCompare(trimmed) == .orderedSame
        })
        if collides {
            renameError = "Another speaker already uses \"\(trimmed)\"."
            return
        }

        do {
            try await env.transcripts.updateSpeakerDisplayName(
                transcriptID: transcriptID,
                canonicalSpeaker: canonical,
                displayName: trimmed
            )
            // Re-fetch so every turn referencing the canonical key
            // re-renders with the new display name.
            await load(id: transcriptID)
        } catch {
            renameError = "\(error)"
        }
    }

    // MARK: - Export / Copy / Save As

    /// Copies the stored markdown to `NSPasteboard.general`. Returns
    /// false if no transcript is loaded (e.g. demo flow).
    @discardableResult
    func copyMarkdownToPasteboard() -> Bool {
        #if canImport(AppKit)
        guard let stored else { return false }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(stored.markdown, forType: .string)
        return true
        #else
        return false
        #endif
    }

    /// Writes the stored markdown to the given URL. Used by SCR-004's
    /// "Save as…" button after `NSSavePanel` returns.
    func saveMarkdown(to url: URL) {
        exportError = nil
        guard let stored else {
            exportError = "No transcript loaded."
            return
        }
        do {
            try stored.markdown.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            exportError = "Couldn't save: \(error.localizedDescription)"
        }
    }

    /// Exports the loaded transcript to the user's configured Obsidian
    /// vault via `ObsidianExporter`. Marks the transcript as exported
    /// on success.
    func exportToObsidian() async {
        exportError = nil
        guard let stored else {
            exportError = "No transcript loaded."
            return
        }
        let vaultPath: String?
        do {
            vaultPath = try await env.settings.read(.obsidianVaultPath)
        } catch {
            exportError = "Couldn't read vault path: \(error.localizedDescription)"
            return
        }
        guard let path = vaultPath, !path.isEmpty else {
            exportError = "Set an Obsidian vault in Settings first."
            return
        }
        let subfolder = (try? await env.settings.read(.obsidianSubfolder)) ?? "Meetings"
        let formatted = Self.makeFormattedTranscript(from: stored)
        do {
            let url = try env.exporter.export(
                transcript: formatted,
                title: stored.title,
                date: stored.date,
                vaultPath: URL(fileURLWithPath: path),
                subfolder: subfolder.isEmpty ? nil : subfolder
            )
            try? await env.transcripts.markExported(id: stored.id, to: url)
            exportedURL = url
        } catch {
            exportError = "Export failed: \(error.localizedDescription)"
        }
    }

    /// Rebuild a `FormattedTranscript` from a `StoredTranscript`. The
    /// `markdown` field is re-emitted from current `DBT-002.display_name`
    /// values (not the at-save-time body) so a rename followed by
    /// Export to Obsidian writes the new names — Codex Gate 5b P1 fix.
    static func makeFormattedTranscript(from stored: StoredTranscript) -> FormattedTranscript {
        let speakerMap = Dictionary(uniqueKeysWithValues: stored.speakers.map {
            ($0.speakerKey, $0.displayName)
        })
        let speakerByID = Dictionary(uniqueKeysWithValues: stored.speakers.map {
            ($0.id, $0)
        })
        let sortedSegments = stored.segments.sorted { $0.sequence < $1.sequence }
        let turns: [TranscriptTurn] = sortedSegments.compactMap { segment in
            guard let speaker = speakerByID[segment.speakerId] else { return nil }
            return TranscriptTurn(
                canonicalSpeaker: speaker.speakerKey,
                displayName: speaker.displayName,
                startSeconds: segment.startTime,
                endSeconds: segment.endTime,
                text: segment.text
            )
        }
        let wordCount = stored.segments.reduce(0) { partial, seg in
            partial + seg.text.split { $0.isWhitespace || $0.isNewline }.count
        }
        let model = WhisperModel(rawValue: stored.model) ?? .baseEN
        return FormattedTranscript(
            markdown: renderMarkdownBody(turns: turns),
            metadata: TranscriptMetadata(
                durationSeconds: stored.durationSeconds,
                speakerCount: stored.speakerCount,
                language: "en",
                model: model,
                wordCount: wordCount,
                turnCount: turns.count
            ),
            speakerMap: speakerMap,
            warnings: [],
            turns: turns
        )
    }

    /// Body-only markdown matching `DefaultTranscriptFormatter`'s emit
    /// shape: `**Display Name** [HH:MM:SS]:\n<text>\n\n…`. We re-emit
    /// here instead of caching the saved body so post-rename exports
    /// reflect the new speaker labels.
    static func renderMarkdownBody(turns: [TranscriptTurn]) -> String {
        var output = ""
        for turn in turns {
            let timestamp = formatTimestamp(turn.startSeconds)
            output += "**\(turn.displayName)** [\(timestamp)]:\n\(turn.text)\n\n"
        }
        // Trim the trailing blank line so the exporter's "\n\n" join with
        // the frontmatter doesn't produce a triple newline.
        while output.hasSuffix("\n\n") { output.removeLast() }
        return output
    }

    // MARK: - Projection

    static func makeDisplayModel(from stored: StoredTranscript) -> TranscriptDisplayModel {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE MMM d · h:mm a"
        let dateLabel = dateFormatter.string(from: stored.date)
        let duration = formatDuration(stored.durationSeconds) + " duration"

        // colorIndex + display name per speaker (sorted by colorIndex so
        // the share bar segments align with the speaker pills).
        let sortedSpeakers = stored.speakers.sorted { $0.colorIndex < $1.colorIndex }
        let totalSpeakingTime = sortedSpeakers
            .compactMap { $0.speakingTimeSeconds }
            .reduce(0, +)
        let displaySpeakers: [TranscriptSpeaker] = sortedSpeakers.map { speaker in
            let speakingTime = speaker.speakingTimeSeconds ?? 0
            let share = totalSpeakingTime > 0 ? speakingTime / totalSpeakingTime : 0
            let isUnlabeled = isCanonicalDefaultName(speaker.displayName)
            return TranscriptSpeaker(
                name: speaker.displayName,
                colorIndex: speaker.colorIndex,
                canonicalKey: speaker.speakerKey,
                time: formatDuration(Int(speakingTime)),
                share: share,
                unlabeled: isUnlabeled
            )
        }

        // speakerId → (display name, colorIndex) for fast turn-row lookup
        let speakerLookup = Dictionary(uniqueKeysWithValues: sortedSpeakers.map {
            ($0.id, ($0.displayName, $0.colorIndex))
        })

        let displayTurns: [DisplayTurn] = stored.segments
            .sorted { $0.sequence < $1.sequence }
            .map { segment in
                let lookup = speakerLookup[segment.speakerId]
                return DisplayTurn(
                    speakerColorIndex: lookup?.1 ?? 0,
                    speakerName: lookup?.0 ?? "Speaker ?",
                    timestamp: formatTimestamp(segment.startTime),
                    text: segment.text
                )
            }

        let wordCount = stored.segments.reduce(0) { partial, seg in
            partial + seg.text.split { $0.isWhitespace || $0.isNewline }.count
        }
        let markdownBytes = formatBytes(stored.markdown.utf8.count)
        let exportTimeFormatter = DateFormatter()
        exportTimeFormatter.dateFormat = "h:mm:ss a"
        let audioDeletedAt = exportTimeFormatter.string(from: stored.updatedAt)

        return TranscriptDisplayModel(
            title: stored.title,
            dateLabel: dateLabel,
            duration: duration,
            speakerCount: stored.speakerCount,
            modelLabel: stored.model,
            speakers: displaySpeakers,
            turns: displayTurns,
            wordCount: wordCount,
            markdownBytes: markdownBytes,
            audioDeletedAt: audioDeletedAt
        )
    }

    private static func formatDuration(_ seconds: Int) -> String {
        let total = max(0, seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    private static func formatTimestamp(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private static func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        let kb = Double(bytes) / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        return String(format: "%.1f MB", kb / 1024.0)
    }

    /// `Speaker N` (the formatter's default unlabeled name) and the
    /// unknown sentinel both count as "unlabeled" for UJ-002's nudge.
    private static func isCanonicalDefaultName(_ name: String) -> Bool {
        if name == DefaultTranscriptFormatter.unknownDisplayName { return true }
        // Matches "Speaker 0", "Speaker 12", etc.
        let parts = name.split(separator: " ")
        if parts.count == 2, parts[0] == "Speaker", Int(parts[1]) != nil { return true }
        return false
    }
}
