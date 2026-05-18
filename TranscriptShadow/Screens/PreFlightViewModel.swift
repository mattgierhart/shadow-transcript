// @implements SCR-001, UJ-001
// View-model for the SCR-001 pre-flight content. Holds source toggles and
// (post Phase 3) the pre-record level preview stream. Phase 1 mirrors the
// existing @State surface so visuals are unchanged.

import Combine
import Foundation

@MainActor
final class PreFlightViewModel: ObservableObject {
    @Published var micEnabled: Bool = true
    @Published var systemAudioEnabled: Bool = true

    let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    /// Phase 2 will load these from `SettingsStore`. Phase 3 will subscribe
    /// to `audioCapture.audioLevels()` for the level preview.
    func load() async {
        // intentionally empty in Phase 1
    }
}
