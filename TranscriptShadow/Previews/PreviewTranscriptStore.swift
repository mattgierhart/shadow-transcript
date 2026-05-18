// @implements API-006, FEA-006
// In-memory `TranscriptStore` used for SwiftUI previews + view-model
// unit tests. Dictionary-backed; supports save / fetch / list / search /
// markExported / delete without touching SQLite.

import Foundation

public final class PreviewTranscriptStore: TranscriptStore, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [UUID: StoredTranscript] = [:]
    private var order: [UUID] = []

    public init(seed: [StoredTranscript] = []) {
        for entry in seed {
            stored[entry.id] = entry
            order.append(entry.id)
        }
    }

    public func save(
        formatted: FormattedTranscript,
        title: String,
        date: Date
    ) async throws -> StoredTranscript {
        let id = UUID()
        let now = Date()
        let speakers = formatted.speakerMap.sorted(by: { $0.key < $1.key }).enumerated().map { idx, pair in
            SpeakerRecord(
                id: UUID().uuidString,
                transcriptId: id.uuidString,
                speakerKey: pair.key,
                displayName: pair.value,
                colorIndex: idx,
                speakingTimeSeconds: nil
            )
        }
        let speakerIDByKey = Dictionary(uniqueKeysWithValues: speakers.map { ($0.speakerKey, $0.id) })
        let segments = formatted.turns.enumerated().compactMap { idx, turn -> SegmentRecord? in
            guard let speakerID = speakerIDByKey[turn.canonicalSpeaker] else { return nil }
            return SegmentRecord(
                id: UUID().uuidString,
                transcriptId: id.uuidString,
                speakerId: speakerID,
                startTime: turn.startSeconds,
                endTime: turn.endSeconds,
                text: turn.text,
                sequence: idx
            )
        }
        let stored = StoredTranscript(
            id: id,
            title: title,
            date: date,
            durationSeconds: formatted.metadata.durationSeconds,
            speakerCount: formatted.metadata.speakerCount,
            markdown: formatted.markdown,
            model: formatted.metadata.model.rawValue,
            exportedPath: nil,
            createdAt: now,
            updatedAt: now,
            speakers: speakers,
            segments: segments
        )
        lock.withLock {
            self.stored[id] = stored
            self.order.insert(id, at: 0)  // newest first
        }
        return stored
    }

    public func fetch(id: UUID) async throws -> StoredTranscript? {
        lock.withLock { stored[id] }
    }

    public func list(limit: Int, offset: Int) async throws -> [StoredTranscriptSummary] {
        lock.withLock {
            let slice = order.dropFirst(offset).prefix(limit)
            return slice.compactMap { stored[$0] }.map(Self.summary(from:))
        }
    }

    public func search(query: String, limit: Int) async throws -> [StoredTranscriptSummary] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let needle = trimmed.lowercased()
        return lock.withLock {
            order.compactMap { stored[$0] }
                .filter { $0.title.lowercased().contains(needle) || $0.markdown.lowercased().contains(needle) }
                .prefix(limit)
                .map(Self.summary(from:))
        }
    }

    public func markExported(id: UUID, to path: URL) async throws {
        try lock.withLock {
            guard let existing = stored[id] else { throw TranscriptStoreError.notFound(id) }
            stored[id] = StoredTranscript(
                id: existing.id,
                title: existing.title,
                date: existing.date,
                durationSeconds: existing.durationSeconds,
                speakerCount: existing.speakerCount,
                markdown: existing.markdown,
                model: existing.model,
                exportedPath: path,
                createdAt: existing.createdAt,
                updatedAt: Date(),
                speakers: existing.speakers,
                segments: existing.segments
            )
        }
    }

    public func delete(id: UUID) async throws {
        try lock.withLock {
            guard stored.removeValue(forKey: id) != nil else {
                throw TranscriptStoreError.notFound(id)
            }
            order.removeAll { $0 == id }
        }
    }

    public func updateSpeakerDisplayName(
        transcriptID: UUID,
        canonicalSpeaker: String,
        displayName: String
    ) async throws {
        try lock.withLock {
            guard let transcript = stored[transcriptID] else {
                throw TranscriptStoreError.notFound(transcriptID)
            }
            guard let speakerIdx = transcript.speakers.firstIndex(where: { $0.speakerKey == canonicalSpeaker }) else {
                throw TranscriptStoreError.notFound(transcriptID)
            }
            var updatedSpeakers = transcript.speakers
            updatedSpeakers[speakerIdx].displayName = displayName
            stored[transcriptID] = StoredTranscript(
                id: transcript.id,
                title: transcript.title,
                date: transcript.date,
                durationSeconds: transcript.durationSeconds,
                speakerCount: transcript.speakerCount,
                markdown: transcript.markdown,
                model: transcript.model,
                exportedPath: transcript.exportedPath,
                createdAt: transcript.createdAt,
                updatedAt: Date(),
                speakers: updatedSpeakers,
                segments: transcript.segments
            )
        }
    }

    private static func summary(from stored: StoredTranscript) -> StoredTranscriptSummary {
        StoredTranscriptSummary(
            id: stored.id,
            title: stored.title,
            date: stored.date,
            durationSeconds: stored.durationSeconds,
            speakerCount: stored.speakerCount,
            exportedPath: stored.exportedPath
        )
    }
}
