// @implements DES-004, SCR-006, UJ-002
// View-model for the SCR-006 history sidebar. Reads `TranscriptStore.list`
// at startup and groups results by date bucket (Today / Yesterday /
// This Week / Older). Search is `TranscriptStore.search` with a 250 ms
// debounce; cancelling the debounced task restores the full list.

import Combine
import Foundation

@MainActor
final class SidebarViewModel: ObservableObject {
    @Published var groups: [SidebarGroup] = []
    @Published var query: String = ""

    let env: AppEnvironment
    private var searchTask: Task<Void, Never>?
    /// Visible for tests. Override with a fixed value so date-bucket
    /// classification is deterministic.
    var now: () -> Date = { Date() }
    /// Debounce window in nanoseconds. Visible for tests so they can drop
    /// to ~0 instead of waiting 250 ms.
    var debounceNanoseconds: UInt64 = 250_000_000

    init(env: AppEnvironment) {
        self.env = env
    }

    func load() async {
        await loadList()
    }

    private func loadList() async {
        let summaries: [StoredTranscriptSummary]
        do {
            summaries = try await env.transcripts.list(limit: 200, offset: 0)
        } catch {
            summaries = []
        }
        if summaries.isEmpty {
            #if DEBUG
            // Empty database — fall back to the canned mock data so
            // SwiftUI previews and a fresh first-launch render still
            // show something. Released builds keep the empty state.
            groups = SidebarMockData.groups
            #else
            groups = []
            #endif
            return
        }
        groups = Self.groupByDateBucket(summaries, now: now())
    }

    func updateQuery(_ newQuery: String) {
        query = newQuery
        searchTask?.cancel()
        let trimmed = newQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            searchTask = Task { @MainActor [weak self] in
                await self?.loadList()
            }
            return
        }
        searchTask = Task { @MainActor [weak self, debounce = debounceNanoseconds] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: debounce)
            guard !Task.isCancelled else { return }
            await self.runSearch(trimmed)
        }
    }

    private func runSearch(_ q: String) async {
        do {
            let results = try await env.transcripts.search(query: q, limit: 200)
            if results.isEmpty {
                groups = []
            } else {
                groups = [SidebarGroup(
                    id: "search",
                    label: "Search · \"\(q)\"",
                    items: results.map { Self.item(from: $0) }
                )]
            }
        } catch {
            groups = []
        }
    }

    // MARK: - Bucketing

    static func groupByDateBucket(
        _ summaries: [StoredTranscriptSummary],
        now: Date,
        calendar: Calendar = .current
    ) -> [SidebarGroup] {
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday),
              let startOfThisWeek = calendar.date(byAdding: .day, value: -7, to: startOfToday)
        else {
            return [SidebarGroup(id: "all", label: "All", items: summaries.map { Self.item(from: $0) })]
        }

        var today: [SidebarItem] = []
        var yesterday: [SidebarItem] = []
        var thisWeek: [SidebarItem] = []
        var older: [SidebarItem] = []
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEE h:mm a"
        let olderFormatter = DateFormatter()
        olderFormatter.dateFormat = "MMM d"

        for summary in summaries {
            let date = summary.date
            let bucketTime: String
            if date >= startOfToday {
                bucketTime = timeFormatter.string(from: date)
                today.append(Self.item(from: summary, time: bucketTime))
            } else if date >= startOfYesterday {
                bucketTime = timeFormatter.string(from: date)
                yesterday.append(Self.item(from: summary, time: bucketTime))
            } else if date >= startOfThisWeek {
                bucketTime = weekdayFormatter.string(from: date)
                thisWeek.append(Self.item(from: summary, time: bucketTime))
            } else {
                bucketTime = olderFormatter.string(from: date)
                older.append(Self.item(from: summary, time: bucketTime))
            }
        }

        var groups: [SidebarGroup] = []
        if !today.isEmpty { groups.append(SidebarGroup(id: "today", label: "Today", items: today)) }
        if !yesterday.isEmpty { groups.append(SidebarGroup(id: "yesterday", label: "Yesterday", items: yesterday)) }
        if !thisWeek.isEmpty { groups.append(SidebarGroup(id: "week", label: "This Week", items: thisWeek)) }
        if !older.isEmpty { groups.append(SidebarGroup(id: "older", label: "Older", items: older)) }
        return groups
    }

    private static func item(from summary: StoredTranscriptSummary, time: String? = nil) -> SidebarItem {
        SidebarItem(
            id: summary.id.uuidString,
            title: summary.title,
            duration: formatDuration(summary.durationSeconds),
            speakers: summary.speakerCount,
            time: time ?? ""
        )
    }

    private static func formatDuration(_ seconds: Int) -> String {
        let total = max(0, seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }
}
