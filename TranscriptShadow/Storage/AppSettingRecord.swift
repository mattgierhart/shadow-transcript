// @implements DBT-101
import Foundation
import GRDB

/// DBT-101 row. Stringly-keyed table where `value` is a JSON-encoded
/// blob holding the typed setting value (handled by `SettingsStore`).
/// Settings without a row fall back to the `SettingKey.defaultValue`
/// the caller passes in — there's no `defaults` migration; defaults
/// are code-resident, not DB-resident.
public struct AppSettingRecord: Codable, FetchableRecord, PersistableRecord, Sendable, Equatable {
    public static let databaseTableName = "app_settings"

    public var key: String
    public var value: String                  // JSON-encoded
    public var updatedAt: String              // ISO8601

    public init(key: String, value: String, updatedAt: String) {
        self.key = key
        self.value = value
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case key
        case value
        case updatedAt = "updated_at"
    }
}
