// @implements DES-004, SCR-006
// Tests for the sidebar view-model. Verifies date-bucket grouping,
// debounced search, and the empty-state fallback.

import XCTest
@testable import TranscriptShadow

@MainActor
final class SidebarViewModelTests: XCTestCase {
    private func makeSummary(
        title: String,
        date: Date,
        duration: Int = 600,
        speakers: Int = 2
    ) -> StoredTranscriptSummary {
        StoredTranscriptSummary(
            id: UUID(),
            title: title,
            date: date,
            durationSeconds: duration,
            speakerCount: speakers,
            exportedPath: nil
        )
    }

    // MARK: - Date bucketing

    func test_listGroupsByDateBucket() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2026, month: 5, day: 17, hour: 14
        ))!

        let todayMorning = calendar.date(byAdding: .hour, value: -8, to: now)!
        let yesterdayAfternoon = calendar.date(byAdding: .day, value: -1, to: now)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now)!

        let summaries = [
            makeSummary(title: "Today AM",     date: todayMorning),
            makeSummary(title: "Yesterday PM", date: yesterdayAfternoon),
            makeSummary(title: "3d ago",       date: threeDaysAgo),
            makeSummary(title: "2w ago",       date: twoWeeksAgo)
        ]

        let groups = SidebarViewModel.groupByDateBucket(summaries, now: now, calendar: calendar)
        XCTAssertEqual(groups.map(\.label), ["Today", "Yesterday", "This Week", "Older"])
        XCTAssertEqual(groups[0].items.map(\.title), ["Today AM"])
        XCTAssertEqual(groups[1].items.map(\.title), ["Yesterday PM"])
        XCTAssertEqual(groups[2].items.map(\.title), ["3d ago"])
        XCTAssertEqual(groups[3].items.map(\.title), ["2w ago"])
    }

    // MARK: - Load

    func test_load_emptyStore_inDebugFallsBackToMockGroups() async {
        let env = AppEnvironment.preview()
        let vm = SidebarViewModel(env: env)
        await vm.load()
        // PreviewTranscriptStore default-seeded with [] → mock groups in DEBUG.
        XCTAssertFalse(vm.groups.isEmpty, "Empty store should surface mock fallback under #if DEBUG")
    }

    func test_load_nonEmptyStore_surfacesStoreData() async throws {
        let store = PreviewTranscriptStore()
        _ = try await store.save(formatted: .preview, title: "Phase-2 sanity", date: Date())

        let env = AppEnvironment(
            audioCapture: PreviewAudioCaptureService(),
            transcription: PreviewTranscriptionService(),
            diarization: FakeDiarizationService(),
            formatter: PreviewTranscriptFormatter(),
            transcripts: store,
            settings: PreviewSettingsStore(),
            exporter: PreviewObsidianExporter()
        )
        let vm = SidebarViewModel(env: env)
        await vm.load()
        let titles = vm.groups.flatMap { $0.items.map(\.title) }
        XCTAssertTrue(titles.contains("Phase-2 sanity"), "Store contents should surface; got \(titles)")
    }

    // MARK: - Search

    func test_searchDebounces_andSurfacesResults() async throws {
        let store = PreviewTranscriptStore()
        _ = try await store.save(formatted: .preview, title: "Q3 Planning",    date: Date())
        _ = try await store.save(formatted: .preview, title: "Lunch meeting",  date: Date())

        let env = AppEnvironment(
            audioCapture: PreviewAudioCaptureService(),
            transcription: PreviewTranscriptionService(),
            diarization: FakeDiarizationService(),
            formatter: PreviewTranscriptFormatter(),
            transcripts: store,
            settings: PreviewSettingsStore(),
            exporter: PreviewObsidianExporter()
        )
        let vm = SidebarViewModel(env: env)
        vm.debounceNanoseconds = 1_000_000  // 1 ms — fast for tests

        vm.updateQuery("Q3")
        XCTAssertEqual(vm.query, "Q3")

        // Give the debounced task time to fire
        try await Task.sleep(nanoseconds: 50_000_000)

        let titles = vm.groups.flatMap { $0.items.map(\.title) }
        XCTAssertEqual(vm.groups.first?.label, "Search · \"Q3\"")
        XCTAssertEqual(titles, ["Q3 Planning"])
    }

    func test_clearingQuery_restoresList() async throws {
        let store = PreviewTranscriptStore()
        _ = try await store.save(formatted: .preview, title: "Q3 Planning",    date: Date())
        _ = try await store.save(formatted: .preview, title: "Lunch meeting",  date: Date())

        let env = AppEnvironment(
            audioCapture: PreviewAudioCaptureService(),
            transcription: PreviewTranscriptionService(),
            diarization: FakeDiarizationService(),
            formatter: PreviewTranscriptFormatter(),
            transcripts: store,
            settings: PreviewSettingsStore(),
            exporter: PreviewObsidianExporter()
        )
        let vm = SidebarViewModel(env: env)
        vm.debounceNanoseconds = 1_000_000

        vm.updateQuery("Q3")
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(vm.groups.first?.label, "Search · \"Q3\"")

        vm.updateQuery("")
        try await Task.sleep(nanoseconds: 50_000_000)
        let titles = vm.groups.flatMap { $0.items.map(\.title) }.sorted()
        XCTAssertEqual(titles, ["Lunch meeting", "Q3 Planning"].sorted())
    }
}
