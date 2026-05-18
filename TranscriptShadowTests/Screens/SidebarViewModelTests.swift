// @implements DES-004, SCR-006
// Tests for the sidebar view-model. Phase 1 verifies the mock-data
// seeding and the search-query passthrough. Phase 2 adds debounced
// `TranscriptStore.search` integration and date-bucket grouping.

import XCTest
@testable import TranscriptShadow

@MainActor
final class SidebarViewModelTests: XCTestCase {
    func test_defaultsToMockGroups() {
        let vm = SidebarViewModel(env: .preview())
        XCTAssertFalse(vm.groups.isEmpty)
        XCTAssertEqual(vm.query, "")
    }

    func test_updateQuerySetsQuery() {
        let vm = SidebarViewModel(env: .preview())
        vm.updateQuery("Q3")
        XCTAssertEqual(vm.query, "Q3")
        vm.updateQuery("")
        XCTAssertEqual(vm.query, "")
    }
}
