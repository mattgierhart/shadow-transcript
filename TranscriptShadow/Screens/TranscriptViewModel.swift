// @implements SCR-004, UJ-002
// View-model for the SCR-004 transcript view. Owns the loaded
// `StoredTranscript` and projects it into a `TranscriptDisplayModel` for
// rendering. Phase 1 hands back the canned `.mock` display model so the
// view renders identically. Phase 2 wires `TranscriptStore.fetch(id:)`
// and the speaker-rename path.

import Combine
import Foundation

@MainActor
final class TranscriptViewModel: ObservableObject {
    @Published var displayModel: TranscriptDisplayModel = .mock
    @Published var loadError: String?
    @Published var renameError: String?

    private(set) var transcriptID: UUID?
    let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
    }

    /// Phase 2 implementation. Today this is a no-op — the view continues
    /// to render `TranscriptDisplayModel.mock` so the existing visual
    /// shell is unchanged.
    func load(id: UUID) async {
        transcriptID = id
        // Phase 2: fetch + project into displayModel
    }

    /// Phase 2 implementation. Will rewrite `displayModel.speakers`
    /// and `displayModel.turns` to swap `canonicalSpeaker → newDisplayName`,
    /// then persist via `TranscriptStore.updateSpeakerDisplayName(...)`.
    func renameSpeaker(canonical: String, to newName: String) async {
        // intentionally empty in Phase 1
    }
}
