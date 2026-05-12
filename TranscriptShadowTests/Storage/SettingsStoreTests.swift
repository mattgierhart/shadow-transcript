// @implements TEST-405, DBT-101
import XCTest
@testable import TranscriptShadow

final class SettingsStoreTests: XCTestCase {
    private var database: AppDatabase!
    private var store: DefaultSettingsStore!

    override func setUpWithError() throws {
        database = try AppDatabase.openInMemory()
        try database.migrate()
        store = DefaultSettingsStore(database: database)
    }

    // MARK: - Defaults

    func test_read_returnsDefault_whenKeyMissing() async throws {
        let subfolder = try await store.read(SettingKey.obsidianSubfolder)
        XCTAssertEqual(subfolder, "Meetings")

        let auto = try await store.read(SettingKey.autoExport)
        XCTAssertEqual(auto, false)

        let model = try await store.read(SettingKey.whisperModel)
        XCTAssertEqual(model, .baseEN)

        let vault = try await store.read(SettingKey.obsidianVaultPath)
        XCTAssertNil(vault)
    }

    // MARK: - Round-trip

    func test_write_andRead_roundTripsString() async throws {
        try await store.write(SettingKey.obsidianSubfolder, "Daily Logs")
        let read = try await store.read(SettingKey.obsidianSubfolder)
        XCTAssertEqual(read, "Daily Logs")
    }

    func test_write_andRead_roundTripsBool() async throws {
        try await store.write(SettingKey.autoExport, true)
        let read = try await store.read(SettingKey.autoExport)
        XCTAssertEqual(read, true)
    }

    func test_write_andRead_roundTripsOptionalString() async throws {
        try await store.write(SettingKey.obsidianVaultPath, "/Users/x/vault")
        let read = try await store.read(SettingKey.obsidianVaultPath)
        XCTAssertEqual(read, "/Users/x/vault")
    }

    func test_write_andRead_roundTripsCustomCodable() async throws {
        try await store.write(SettingKey.whisperModel, .smallEN)
        let read = try await store.read(SettingKey.whisperModel)
        XCTAssertEqual(read, .smallEN)
    }

    // MARK: - Upsert

    func test_write_twice_updatesExistingValue() async throws {
        try await store.write(SettingKey.obsidianSubfolder, "First")
        try await store.write(SettingKey.obsidianSubfolder, "Second")
        let read = try await store.read(SettingKey.obsidianSubfolder)
        XCTAssertEqual(read, "Second")
    }

    // MARK: - Reset

    func test_reset_restoresDefault() async throws {
        try await store.write(SettingKey.autoExport, true)
        try await store.reset(SettingKey.autoExport)
        let read = try await store.read(SettingKey.autoExport)
        XCTAssertEqual(read, false)
    }

    // MARK: - Bad data tolerance

    func test_read_returnsDefault_whenStoredValueIsCorrupt() async throws {
        // Manually insert garbage so the decode path fails.
        try await database.queue.write { conn in
            try conn.execute(
                sql: "INSERT INTO app_settings (key, value, updated_at) VALUES (?, ?, ?)",
                arguments: [
                    SettingKey.obsidianSubfolder.rawKey,
                    "{not valid json",
                    ISO8601.string(from: Date()),
                ]
            )
        }
        let read = try await store.read(SettingKey.obsidianSubfolder)
        XCTAssertEqual(read, "Meetings", "Bad JSON must fall back to default, not crash")
    }
}
