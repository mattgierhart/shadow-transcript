// @implements API-006, DBT-101
// In-memory `SettingsStore` used for SwiftUI previews + view-model unit
// tests. Stores values as JSON-encoded envelopes — mirrors
// `DefaultSettingsStore`'s storage shape so the contract is identical.

import Foundation

public final class PreviewSettingsStore: SettingsStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Data] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(seed: [String: Data] = [:]) {
        self.storage = seed
    }

    public func read<T: Codable & Sendable>(_ key: SettingKey<T>) async throws -> T {
        let data = lock.withLock { storage[key.rawKey] }
        guard let data else { return key.defaultValue }
        guard let envelope = try? decoder.decode(SettingEnvelope<T>.self, from: data) else {
            return key.defaultValue
        }
        return envelope.value
    }

    public func write<T: Codable & Sendable>(_ key: SettingKey<T>, _ value: T) async throws {
        let envelope = SettingEnvelope(value: value)
        let data = try encoder.encode(envelope)
        lock.withLock { storage[key.rawKey] = data }
    }

    public func reset<T: Codable & Sendable>(_ key: SettingKey<T>) async throws {
        lock.withLock { _ = storage.removeValue(forKey: key.rawKey) }
    }
}
