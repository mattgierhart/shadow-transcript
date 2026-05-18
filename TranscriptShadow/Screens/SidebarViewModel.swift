// @implements DES-004, SCR-006, UJ-002
// View-model for the SCR-006 history sidebar. Phase 1 returns the
// existing `SidebarMockData.groups` so the visuals don't change. Phase 2
// wires `TranscriptStore.list(limit:offset:)` and a 250ms-debounced
// `TranscriptStore.search(query:limit:)`.

import Combine
import Foundation

@MainActor
final class SidebarViewModel: ObservableObject {
    @Published var groups: [SidebarGroup] = SidebarMockData.groups
    @Published var query: String = ""

    let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    /// Phase 2 implementation: `TranscriptStore.list(limit:offset:)` →
    /// group by date bucket (Today / Yesterday / This Week / Older).
    func load() async {
        // intentionally empty in Phase 1
    }

    /// Phase 2 implementation: 250ms-debounced
    /// `TranscriptStore.search(query:limit:)`.
    func updateQuery(_ newQuery: String) {
        query = newQuery
        // Phase 2: cancel + reschedule debounced search task
    }
}
