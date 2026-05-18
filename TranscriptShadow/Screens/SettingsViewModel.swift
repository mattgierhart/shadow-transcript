// @implements SCR-005, UJ-003, DBT-101
// View-model for the SCR-005 settings sheet. Reads every typed key from
// `SettingsStore` on `.task` and persists changes through explicit
// setter methods so the bindings flow `View → setX(...) → SettingsStore`
// (no @Published feedback loop with the store).

import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var inputDevice: String = SettingKey<String>.audioInputDevice.defaultValue
    @Published private(set) var captureSystemAudio: Bool = SettingKey<Bool>.captureSystemAudio.defaultValue
    @Published private(set) var whisperModel: WhisperModel = SettingKey<WhisperModel>.whisperModel.defaultValue
    @Published var diarizationOn: Bool = true  // not a persisted key yet — UI only
    @Published private(set) var vaultPath: String = ""
    @Published private(set) var subfolder: String = SettingKey<String>.obsidianSubfolder.defaultValue
    @Published private(set) var autoExport: Bool = SettingKey<Bool>.autoExport.defaultValue

    let env: AppEnvironment
    private var hasLoaded = false

    init(env: AppEnvironment) {
        self.env = env
    }

    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        do {
            inputDevice = try await env.settings.read(.audioInputDevice)
            captureSystemAudio = try await env.settings.read(.captureSystemAudio)
            whisperModel = try await env.settings.read(.whisperModel)
            vaultPath = (try await env.settings.read(.obsidianVaultPath)) ?? ""
            subfolder = try await env.settings.read(.obsidianSubfolder)
            autoExport = try await env.settings.read(.autoExport)
        } catch {
            // ignore — keys keep their defaults
        }
    }

    // MARK: - Setters (each writes through to SettingsStore)

    func setInputDevice(_ value: String) {
        inputDevice = value
        Task { try? await env.settings.write(.audioInputDevice, value) }
    }

    func setCaptureSystemAudio(_ value: Bool) {
        captureSystemAudio = value
        Task { try? await env.settings.write(.captureSystemAudio, value) }
    }

    func setWhisperModel(_ value: WhisperModel) {
        whisperModel = value
        Task { try? await env.settings.write(.whisperModel, value) }
    }

    func setVaultPath(_ value: String) {
        vaultPath = value
        let stored: String? = value.isEmpty ? nil : value
        Task { try? await env.settings.write(.obsidianVaultPath, stored) }
    }

    func setSubfolder(_ value: String) {
        subfolder = value
        Task { try? await env.settings.write(.obsidianSubfolder, value) }
    }

    func setAutoExport(_ value: Bool) {
        autoExport = value
        Task { try? await env.settings.write(.autoExport, value) }
    }
}
