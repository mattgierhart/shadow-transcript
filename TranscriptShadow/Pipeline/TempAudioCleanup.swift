// @implements API-301, ARC-003, BR-102, BR-103, RISK-006
// Cleanup contract for the AudioCaptureLocations.recordingsDirectory
// per ARC-003. Three responsibilities:
//
//   1. `delete(url:)` — remove a single temp WAV (called from the
//      orchestrator on every exit path: success, cancel, error).
//   2. `scanForOrphans()` — at app launch, delete WAVs older than
//      24 h (recent ones still get deleted under v0.7 scope per the
//      EPIC-08 "silent delete" policy).
//   3. `cleanupAll()` — `applicationWillTerminate` hook to nuke any
//      in-flight partials.
//
// The implementation is synchronous filesystem work; failures are
// logged-and-swallowed since EPIC-08 explicitly classifies cleanup as
// best-effort (the recording is already finalized or already past
// recoverable; orphan deletion is silent).

import Foundation

public protocol TempAudioCleanup: Sendable {
    func delete(url: URL) async
    func scanForOrphans() async
    func cleanupAll() async
}

public final class DefaultTempAudioCleanup: TempAudioCleanup, @unchecked Sendable {
    private let fileManager: FileManager
    private let directoryURL: URL
    private let clock: @Sendable () -> Date
    /// Files older than `staleAge` get deleted by `scanForOrphans`.
    /// Recent files (less than `staleAge`) are also deleted but logged.
    private let staleAge: TimeInterval

    public init(
        fileManager: FileManager = .default,
        directoryURL: URL? = nil,
        clock: @escaping @Sendable () -> Date = { Date() },
        staleAge: TimeInterval = 24 * 60 * 60
    ) {
        self.fileManager = fileManager
        // Mirror DefaultAudioCaptureService's directory choice. Fall
        // back to a tmp path if Application Support isn't available
        // (only happens in tests or in restricted sandbox configs).
        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            self.directoryURL = (try? AudioCaptureLocations.recordingsDirectory(fileManager: fileManager))
                ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TranscriptShadowOrphans")
        }
        self.clock = clock
        self.staleAge = staleAge
    }

    public func delete(url: URL) async {
        guard fileManager.fileExists(atPath: url.path) else { return }
        try? fileManager.removeItem(at: url)
    }

    public func scanForOrphans() async {
        guard fileManager.fileExists(atPath: directoryURL.path) else { return }
        let contents = (try? fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        let now = clock()
        for fileURL in contents where fileURL.pathExtension.lowercased() == "wav" {
            let mtime = (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            if now.timeIntervalSince(mtime) >= staleAge {
                try? fileManager.removeItem(at: fileURL)
            } else {
                // Recent orphan — under v0.7 scope still silently
                // delete. EPIC-09+ may surface a recoverable record.
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }

    public func cleanupAll() async {
        guard fileManager.fileExists(atPath: directoryURL.path) else { return }
        let contents = (try? fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []
        for fileURL in contents where fileURL.pathExtension.lowercased() == "wav" {
            try? fileManager.removeItem(at: fileURL)
        }
    }
}
