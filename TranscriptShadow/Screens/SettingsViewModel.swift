// @implements SCR-005, UJ-003
// View-model for the SCR-005 settings sheet. Phase 1 mirrors the
// existing @State surface so the visuals are identical. Phase 2 wires
// each property to a `SettingsStore` typed key: reads on `.task`, writes
// on every change.

import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var inputDevice: String = "MacBook Pro Microphone"
    @Published var captureSystemAudio: Bool = true
    @Published var whisperModel: WhisperModel = .smallEN
    @Published var diarizationOn: Bool = true
    @Published var vaultPath: String = "~/Vaults/work-notes"
    @Published var subfolder: String = "Meetings"
    @Published var autoExport: Bool = false

    let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    /// Phase 2 will read every key from `SettingsStore` and bind writes.
    /// Today it's a no-op so existing visuals are unchanged.
    func load() async {
        // intentionally empty in Phase 1
    }
}
