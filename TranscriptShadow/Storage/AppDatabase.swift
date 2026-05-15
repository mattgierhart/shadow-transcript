// @implements TECH-007, BR-201, FEA-005, FEA-006
import Foundation
import GRDB

/// Thin wrapper around a GRDB `DatabaseQueue` plus the migration runner
/// (`DatabaseMigrations`). One instance per app process; both
/// `TranscriptStore` and `SettingsStore` share it.
///
/// - File location: `~/Library/Application Support/TranscriptShadow/transcripts.sqlite`
///   (mirrors the `AudioCaptureLocations` directory pattern).
/// - Foreign keys are enabled on every opened connection via
///   `Configuration.prepareDatabase`. GRDB doesn't enable FKs by
///   default (SQLite legacy) so the per-connection PRAGMA is required;
///   otherwise the `ON DELETE CASCADE` declarations in DBT-002/003 are
///   silently no-ops.
/// - Use `openInMemory()` in tests to avoid touching the user's
///   Application Support directory.
/// - `queue` is `internal` so the in-module stores can use it but
///   external callers must go through `TranscriptStore` / `SettingsStore`.
///   Tests reach it via `@testable import`.
public final class AppDatabase: Sendable {
    let queue: DatabaseQueue

    public init(queue: DatabaseQueue) {
        self.queue = queue
    }

    public static func openOnDisk(fileManager: FileManager = .default) throws -> AppDatabase {
        let url = try databaseURL(fileManager: fileManager)
        let configuration = makeConfiguration()
        let queue = try DatabaseQueue(path: url.path, configuration: configuration)
        return AppDatabase(queue: queue)
    }

    public static func openInMemory() throws -> AppDatabase {
        let configuration = makeConfiguration()
        let queue = try DatabaseQueue(configuration: configuration)
        return AppDatabase(queue: queue)
    }

    /// Runs all registered migrations. Idempotent — safe to call on
    /// every launch. The single v1 migration creates DBT-001..003 +
    /// DBT-101 + FTS5 + sync triggers.
    public func migrate() throws {
        try DatabaseMigrations.migrator().migrate(queue)
    }

    /// `~/Library/Application Support/TranscriptShadow/transcripts.sqlite`
    public static func databaseURL(fileManager: FileManager = .default) throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = appSupport.appendingPathComponent("TranscriptShadow", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("transcripts.sqlite", isDirectory: false)
    }

    private static func makeConfiguration() -> Configuration {
        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        return config
    }
}
