// @implements DBT-101, FEA-005
import Foundation
import GRDB

/// Typed key-value settings backed by DBT-101. Each setting has a
/// stable string key + a Codable value type + a code-resident default.
/// `read` returns the default when the row is missing; `write` upserts.
///
/// Why JSON-in-TEXT (vs. native column types per setting)? Forward
/// compatibility — a future setting whose value is a struct
/// (`[ObsidianExportPreset]`) needs no migration; the encoder handles
/// it. Cost: invalid JSON in storage falls back to the default rather
/// than crashing the read.
public protocol SettingsStore: Sendable {
    func read<T: Codable & Sendable>(_ key: SettingKey<T>) async throws -> T
    func write<T: Codable & Sendable>(_ key: SettingKey<T>, _ value: T) async throws
    func reset<T: Codable & Sendable>(_ key: SettingKey<T>) async throws
}

public struct SettingKey<Value: Codable & Sendable>: Sendable {
    public let rawKey: String
    public let defaultValue: Value

    public init(rawKey: String, defaultValue: Value) {
        self.rawKey = rawKey
        self.defaultValue = defaultValue
    }
}

// MARK: - Built-in keys (DBT-101 spec)

public extension SettingKey where Value == String? {
    /// Absolute path to the user's Obsidian vault root. `nil` means
    /// "not configured yet" — the UI must prompt during onboarding.
    static var obsidianVaultPath: SettingKey<String?> {
        SettingKey<String?>(rawKey: "obsidian_vault_path", defaultValue: nil)
    }
}

public extension SettingKey where Value == String {
    /// Subfolder within the vault where exports land. Defaults to
    /// "Meetings" per DBT-101.
    static var obsidianSubfolder: SettingKey<String> {
        SettingKey<String>(rawKey: "obsidian_subfolder", defaultValue: "Meetings")
    }

    /// Preferred audio input device name. `""` means system default
    /// (DBT-101).
    static var audioInputDevice: SettingKey<String> {
        SettingKey<String>(rawKey: "audio_input_device", defaultValue: "")
    }
}

public extension SettingKey where Value == Bool {
    static var captureMicrophone: SettingKey<Bool> {
        SettingKey<Bool>(rawKey: "capture_microphone", defaultValue: true)
    }

    static var captureSystemAudio: SettingKey<Bool> {
        SettingKey<Bool>(rawKey: "capture_system_audio", defaultValue: true)
    }

    static var autoExport: SettingKey<Bool> {
        SettingKey<Bool>(rawKey: "auto_export", defaultValue: false)
    }

    /// When true (default), the pipeline runs the on-device summarizer
    /// (API-401 / FEA-007) after formatting and embeds the summary into
    /// the transcript markdown. On-device only — BR-104.
    static var summarizeOnComplete: SettingKey<Bool> {
        SettingKey<Bool>(rawKey: "summarize_on_complete", defaultValue: true)
    }
}

public extension SettingKey where Value == WhisperModel {
    static var whisperModel: SettingKey<WhisperModel> {
        SettingKey<WhisperModel>(rawKey: "whisper_model", defaultValue: .baseEN)
    }
}

// MARK: - Default impl

public final class DefaultSettingsStore: SettingsStore, Sendable {
    private let database: AppDatabase
    private let clock: @Sendable () -> Date
    private let encoder: @Sendable () -> JSONEncoder
    private let decoder: @Sendable () -> JSONDecoder

    public init(
        database: AppDatabase,
        clock: @escaping @Sendable () -> Date = { Date() },
        encoder: @escaping @Sendable () -> JSONEncoder = { JSONEncoder() },
        decoder: @escaping @Sendable () -> JSONDecoder = { JSONDecoder() }
    ) {
        self.database = database
        self.clock = clock
        self.encoder = encoder
        self.decoder = decoder
    }

    public func read<T: Codable & Sendable>(_ key: SettingKey<T>) async throws -> T {
        let value = try await database.queue.read { db -> T? in
            guard let record = try AppSettingRecord.fetchOne(db, key: key.rawKey),
                  let data = record.value.data(using: .utf8) else {
                return nil
            }
            // Foundation can't decode top-level fragments by default; wrap
            // values in a one-key envelope before encoding (`write` does
            // the same).
            let decoder = self.decoder()
            return try? decoder.decode(SettingEnvelope<T>.self, from: data).value
        }
        return value ?? key.defaultValue
    }

    public func write<T: Codable & Sendable>(_ key: SettingKey<T>, _ value: T) async throws {
        let envelope = SettingEnvelope(value: value)
        let data = try encoder().encode(envelope)
        guard let json = String(data: data, encoding: .utf8) else {
            throw SettingsStoreError.encodingFailed(key: key.rawKey)
        }
        let updatedAt = ISO8601.string(from: clock())
        try await database.queue.write { db in
            try db.execute(
                sql: """
                    INSERT INTO app_settings (key, value, updated_at)
                    VALUES (?, ?, ?)
                    ON CONFLICT(key) DO UPDATE SET
                        value = excluded.value,
                        updated_at = excluded.updated_at
                """,
                arguments: [key.rawKey, json, updatedAt]
            )
        }
    }

    public func reset<T: Codable & Sendable>(_ key: SettingKey<T>) async throws {
        try await database.queue.write { db in
            // Explicit SQL avoids relying on GRDB's auto-derived
            // primary-key inference for `AppSettingRecord`, whose PK
            // column is `key` (not `id`).
            try db.execute(
                sql: "DELETE FROM app_settings WHERE key = ?",
                arguments: [key.rawKey]
            )
        }
    }
}

public enum SettingsStoreError: Error, Equatable {
    case encodingFailed(key: String)
}

/// JSON envelope so we can serialize top-level fragments (Bool, String,
/// optional, etc.) which JSONEncoder otherwise rejects pre-iOS 13.
/// Internal — the storage shape is `{"value": <T>}` and never observed
/// by callers.
struct SettingEnvelope<T: Codable>: Codable {
    let value: T
}
