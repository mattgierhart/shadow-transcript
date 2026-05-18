// @implements SCR-005, UJ-003, DBT-101
// Settings view-model round-trip tests. Verifies that each setter
// writes to SettingsStore and a fresh VM with the same store can read
// the change back.

import XCTest
@testable import TranscriptShadow

@MainActor
final class SettingsViewModelTests: XCTestCase {
    private func makeEnv(settings: PreviewSettingsStore = PreviewSettingsStore()) -> AppEnvironment {
        AppEnvironment(
            audioCapture: PreviewAudioCaptureService(),
            transcription: PreviewTranscriptionService(),
            diarization: FakeDiarizationService(),
            formatter: PreviewTranscriptFormatter(),
            transcripts: PreviewTranscriptStore(),
            settings: settings,
            exporter: PreviewObsidianExporter()
        )
    }

    func test_defaults_matchSettingKeyDefaults() {
        let vm = SettingsViewModel(env: makeEnv())
        XCTAssertEqual(vm.inputDevice, SettingKey<String>.audioInputDevice.defaultValue)
        XCTAssertEqual(vm.captureSystemAudio, SettingKey<Bool>.captureSystemAudio.defaultValue)
        XCTAssertEqual(vm.whisperModel, SettingKey<WhisperModel>.whisperModel.defaultValue)
        XCTAssertEqual(vm.subfolder, SettingKey<String>.obsidianSubfolder.defaultValue)
        XCTAssertEqual(vm.autoExport, SettingKey<Bool>.autoExport.defaultValue)
        XCTAssertEqual(vm.vaultPath, "")
    }

    func test_eachKeyRoundTrips_acrossVMReinit() async throws {
        let store = PreviewSettingsStore()
        let env = makeEnv(settings: store)

        let vm = SettingsViewModel(env: env)
        await vm.load()
        vm.setInputDevice("AirPods Pro")
        vm.setCaptureSystemAudio(false)
        vm.setWhisperModel(.mediumEN)
        vm.setVaultPath("/Users/test/vault")
        vm.setSubfolder("Calls")
        vm.setAutoExport(true)

        // Pump the Task closures the setters kicked off
        try await Task.sleep(nanoseconds: 30_000_000)

        let vm2 = SettingsViewModel(env: env)
        await vm2.load()
        XCTAssertEqual(vm2.inputDevice, "AirPods Pro")
        XCTAssertFalse(vm2.captureSystemAudio)
        XCTAssertEqual(vm2.whisperModel, .mediumEN)
        XCTAssertEqual(vm2.vaultPath, "/Users/test/vault")
        XCTAssertEqual(vm2.subfolder, "Calls")
        XCTAssertTrue(vm2.autoExport)
    }

    func test_setVaultPath_emptyStringStoresNil() async throws {
        let store = PreviewSettingsStore()
        let env = makeEnv(settings: store)

        let vm = SettingsViewModel(env: env)
        await vm.load()
        vm.setVaultPath("/tmp/vault")
        try await Task.sleep(nanoseconds: 30_000_000)
        vm.setVaultPath("")
        try await Task.sleep(nanoseconds: 30_000_000)

        let stored = try await store.read(.obsidianVaultPath)
        XCTAssertNil(stored, "Empty string should clear the obsidianVaultPath key")
    }
}
