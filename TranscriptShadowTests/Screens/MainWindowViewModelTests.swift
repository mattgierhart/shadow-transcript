// @implements SCR-001, SCR-003, SCR-004
// State-machine tests for the main-window view-model. Verifies the
// content swap (preFlight → processing → transcript) and the settings
// sheet toggle. Phase 3 will add a record-flow test against the real
// `AudioCaptureService` (or a richer preview fake).

import XCTest
@testable import TranscriptShadow

@MainActor
final class MainWindowViewModelTests: XCTestCase {
    func test_defaultsToPreFlight_andEmptySelection() {
        let vm = MainWindowViewModel(env: .preview())
        XCTAssertEqual(vm.content, .preFlight)
        XCTAssertNil(vm.selectedTranscriptID)
        XCTAssertFalse(vm.showSettings)
    }

    func test_selectTranscript_transitionsToTranscriptState() {
        let vm = MainWindowViewModel(env: .preview())
        vm.selectTranscript(id: "t1")
        XCTAssertEqual(vm.content, .transcript(id: "t1"))
        XCTAssertEqual(vm.selectedTranscriptID, "t1")
    }

    func test_goToPreFlight_clearsSelection() {
        let vm = MainWindowViewModel(env: .preview())
        vm.selectTranscript(id: "t1")
        vm.goToPreFlight()
        XCTAssertEqual(vm.content, .preFlight)
        XCTAssertNil(vm.selectedTranscriptID)
    }

    func test_goToProcessing_clearsSelection() {
        let vm = MainWindowViewModel(env: .preview())
        vm.selectTranscript(id: "t1")
        vm.goToProcessing()
        XCTAssertEqual(vm.content, .processing(audioURL: nil))
        XCTAssertNil(vm.selectedTranscriptID)
    }

    func test_settingsSheetTogglesViaOpenAndClose() {
        let vm = MainWindowViewModel(env: .preview())
        vm.openSettings()
        XCTAssertTrue(vm.showSettings)
        vm.closeSettings()
        XCTAssertFalse(vm.showSettings)
    }
}
