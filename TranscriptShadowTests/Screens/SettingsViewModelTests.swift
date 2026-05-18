// @implements SCR-005, UJ-003
// Tests for the settings view-model. Phase 1 only verifies the
// @Published surface defaults and that the VM holds onto its environment.
// Phase 2 will add round-trip tests against `SettingsStore`.

import XCTest
@testable import TranscriptShadow

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func test_defaults_matchDesignSpec() {
        let vm = SettingsViewModel(env: .preview())
        XCTAssertEqual(vm.inputDevice, "MacBook Pro Microphone")
        XCTAssertTrue(vm.captureSystemAudio)
        XCTAssertEqual(vm.whisperModel, .smallEN)
        XCTAssertTrue(vm.diarizationOn)
        XCTAssertEqual(vm.vaultPath, "~/Vaults/work-notes")
        XCTAssertEqual(vm.subfolder, "Meetings")
        XCTAssertFalse(vm.autoExport)
    }

    func test_loadIsIdempotent() async {
        let vm = SettingsViewModel(env: .preview())
        await vm.load()
        await vm.load()
        XCTAssertEqual(vm.subfolder, "Meetings")  // unchanged
    }
}
