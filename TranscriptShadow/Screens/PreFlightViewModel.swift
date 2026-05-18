// @implements SCR-001, UJ-001, DBT-101
// View-model for the SCR-001 pre-flight content. Owns the source
// toggles and persists their state through `SettingsStore` so
// `MainWindowViewModel.handleRecord` picks up whichever sources the
// user actually selected (Codex Gate 5b P2 fix).

import Combine
import Foundation

@MainActor
final class PreFlightViewModel: ObservableObject {
    @Published private(set) var micEnabled: Bool = SettingKey<Bool>.captureMicrophone.defaultValue
    @Published private(set) var systemAudioEnabled: Bool = SettingKey<Bool>.captureSystemAudio.defaultValue

    let env: AppEnvironment
    private var hasLoaded = false

    init(env: AppEnvironment) {
        self.env = env
    }

    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        do {
            micEnabled = try await env.settings.read(.captureMicrophone)
            systemAudioEnabled = try await env.settings.read(.captureSystemAudio)
        } catch {
            // ignore — keys keep their defaults
        }
    }

    func setMicEnabled(_ value: Bool) {
        micEnabled = value
        Task { try? await env.settings.write(.captureMicrophone, value) }
    }

    func setSystemAudioEnabled(_ value: Bool) {
        systemAudioEnabled = value
        Task { try? await env.settings.write(.captureSystemAudio, value) }
    }
}
