// @implements API-301, ARC-003, BR-102, BR-103, TEST-501, TEST-503
// Tests for DefaultTempAudioCleanup. Covers single-file delete,
// orphan scan on launch, and full cleanup on terminate.

import XCTest
@testable import TranscriptShadow

final class TempAudioCleanupTests: XCTestCase {
    private var sandboxDir: URL!
    private let fileManager = FileManager.default

    override func setUpWithError() throws {
        sandboxDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("TempAudioCleanupTests-\(UUID().uuidString.prefix(8))")
        try fileManager.createDirectory(at: sandboxDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: sandboxDir)
        sandboxDir = nil
    }

    private func makeWAV(named name: String, age: TimeInterval = 0) throws -> URL {
        let url = sandboxDir.appendingPathComponent(name)
        try Data([0x00, 0x01, 0x02]).write(to: url)
        if age > 0 {
            let mtime = Date().addingTimeInterval(-age)
            try fileManager.setAttributes(
                [.modificationDate: mtime],
                ofItemAtPath: url.path
            )
        }
        return url
    }

    // MARK: - delete(url:)

    func test_delete_removesSingleWAV() async throws {
        let url = try makeWAV(named: "single.wav")
        XCTAssertTrue(fileManager.fileExists(atPath: url.path))
        let cleanup = DefaultTempAudioCleanup(directoryURL: sandboxDir)
        await cleanup.delete(url: url)
        XCTAssertFalse(fileManager.fileExists(atPath: url.path), "TEST-501 — single-file delete should remove the WAV")
    }

    func test_delete_isIdempotent_forMissingFile() async throws {
        let url = sandboxDir.appendingPathComponent("never-existed.wav")
        let cleanup = DefaultTempAudioCleanup(directoryURL: sandboxDir)
        await cleanup.delete(url: url)
        // No throw, no crash — just a silent no-op
    }

    // MARK: - scanForOrphans

    func test_scanForOrphans_deletesAllWAVs() async throws {
        let a = try makeWAV(named: "old-1.wav", age: 48 * 3600)
        let b = try makeWAV(named: "old-2.wav", age: 25 * 3600)
        let c = try makeWAV(named: "fresh.wav", age: 10)
        let cleanup = DefaultTempAudioCleanup(directoryURL: sandboxDir)
        await cleanup.scanForOrphans()
        XCTAssertFalse(fileManager.fileExists(atPath: a.path))
        XCTAssertFalse(fileManager.fileExists(atPath: b.path))
        // Recent files also get deleted under the v0.7 "silent delete"
        // policy.
        XCTAssertFalse(fileManager.fileExists(atPath: c.path), "TEST-503 — orphan scan deletes all WAVs (v0.7 silent-delete policy)")
    }

    func test_scanForOrphans_skipsNonWAV() async throws {
        let wav = try makeWAV(named: "audio.wav")
        let log = sandboxDir.appendingPathComponent("not-audio.log")
        try Data([0xFF]).write(to: log)
        let cleanup = DefaultTempAudioCleanup(directoryURL: sandboxDir)
        await cleanup.scanForOrphans()
        XCTAssertFalse(fileManager.fileExists(atPath: wav.path))
        XCTAssertTrue(fileManager.fileExists(atPath: log.path), "Scan must not touch non-WAV files")
    }

    func test_scanForOrphans_handlesMissingDirectory() async throws {
        let cleanup = DefaultTempAudioCleanup(directoryURL: sandboxDir.appendingPathComponent("does-not-exist"))
        await cleanup.scanForOrphans()
        // No throw — silent no-op
    }

    // MARK: - cleanupAll

    func test_cleanupAll_removesAllWAVs_irrespectiveOfAge() async throws {
        let a = try makeWAV(named: "old.wav", age: 48 * 3600)
        let b = try makeWAV(named: "fresh.wav", age: 1)
        let cleanup = DefaultTempAudioCleanup(directoryURL: sandboxDir)
        await cleanup.cleanupAll()
        XCTAssertFalse(fileManager.fileExists(atPath: a.path))
        XCTAssertFalse(fileManager.fileExists(atPath: b.path))
    }
}
