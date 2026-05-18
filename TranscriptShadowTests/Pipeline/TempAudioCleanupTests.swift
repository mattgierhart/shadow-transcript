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

    func test_scanForOrphans_deletesOrphansOlderThanInFlightWindow() async throws {
        let a = try makeWAV(named: "old-1.wav", age: 48 * 3600)
        let b = try makeWAV(named: "old-2.wav", age: 25 * 3600)
        let c = try makeWAV(named: "recent-orphan.wav", age: 5 * 60)  // 5 min
        let cleanup = DefaultTempAudioCleanup(directoryURL: sandboxDir)
        await cleanup.scanForOrphans()
        XCTAssertFalse(fileManager.fileExists(atPath: a.path))
        XCTAssertFalse(fileManager.fileExists(atPath: b.path))
        XCTAssertFalse(fileManager.fileExists(atPath: c.path),
                       "TEST-503 — anything outside the in-flight window is treated as orphan")
    }

    func test_scanForOrphans_skipsInFlightWAV_avoidingActiveCaptureRace() async throws {
        // Codex Gate 6 P2 — a brand-new capture started ~seconds after
        // the launch scan kicked off must not be deleted.
        let inflight = try makeWAV(named: "inflight.wav", age: 5)  // 5 s old
        let cleanup = DefaultTempAudioCleanup(directoryURL: sandboxDir, inFlightWindow: 30)
        await cleanup.scanForOrphans()
        XCTAssertTrue(fileManager.fileExists(atPath: inflight.path),
                      "Scan must preserve files within the in-flight window")
    }

    func test_scanForOrphans_skipsNonWAV() async throws {
        let wav = try makeWAV(named: "audio.wav", age: 10 * 60)  // 10 min — outside window
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
