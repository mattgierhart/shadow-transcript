// @implements DES-004 (Sidebar Transcript List), SCR-006 (Transcript History)
// @see SoT/SoT.DESIGN_COMPONENTS.md DES-004
// @see design/visual-prototype/project/src/shared.jsx :: Sidebar
// @see design/visual-prototype/project/src/scr006.jsx :: SidebarSearching, ContextMenu
//
// Always-visible transcript history sidebar. Mock data embedded for the
// UI shell; production wires to TranscriptStore.list() and
// TranscriptStore.search() for the filter case.

import SwiftUI

struct SidebarItem: Identifiable, Equatable {
    let id: String
    let title: String
    let duration: String
    let speakers: Int
    let time: String
}

struct SidebarGroup: Identifiable {
    let id: String
    let label: String
    let items: [SidebarItem]
}

struct Sidebar: View {
    let groups: [SidebarGroup]
    @Binding var selectedID: String?
    @State private var query: String = ""
    @FocusState private var searchFocused: Bool

    init(groups: [SidebarGroup] = SidebarMockData.groups, selectedID: Binding<String?>) {
        self.groups = groups
        self._selectedID = selectedID
    }

    private var isSearching: Bool { !query.isEmpty }

    private var filteredGroups: [SidebarGroup] {
        guard isSearching else { return groups }
        let q = query.lowercased()
        let matches = groups
            .flatMap(\.items)
            .filter { $0.title.lowercased().contains(q) }
        guard !matches.isEmpty else { return [] }
        return [SidebarGroup(id: "search", label: "Search · \"\(query)\"", items: matches)]
    }

    private var totalCount: Int {
        groups.reduce(0) { $0 + $1.items.count }
    }

    private var matchCount: Int {
        filteredGroups.reduce(0) { $0 + $1.items.count }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            list
            footer
        }
        .frame(width: DesignSpacing.Layout.sidebarDefault)
        .background(DesignColors.bgSecondary)
        .overlay(
            Rectangle().fill(DesignColors.borderDefault).frame(width: 0.5),
            alignment: .trailing
        )
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(isSearching ? DesignColors.accentPrimary : DesignColors.textMuted)

            TextField("Search transcripts", text: $query)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .font(DesignFonts.ui(12))
                .foregroundStyle(DesignColors.textPrimary)

            if isSearching {
                Text("\(matchCount) \(matchCount == 1 ? "match" : "matches")")
                    .font(DesignFonts.mono(10))
                    .foregroundStyle(DesignColors.textMuted)
                Button(action: { query = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignColors.textMuted)
                }
                .buttonStyle(.plain)
            } else {
                Text("⌘F")
                    .font(DesignFonts.mono(10))
                    .foregroundStyle(DesignColors.textMuted.opacity(0.7))
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(DesignColors.bgTertiary)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSearching ? DesignColors.accentPrimary.opacity(0.55) : DesignColors.borderDefault,
                        lineWidth: isSearching ? 1 : 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - List

    private var list: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                if filteredGroups.isEmpty && isSearching {
                    emptyResults
                } else {
                    ForEach(filteredGroups) { group in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(group.label.uppercased())
                                .font(DesignFonts.ui(10, weight: .semibold))
                                .tracking(0.6)
                                .foregroundStyle(DesignColors.textMuted)
                                .padding(.horizontal, 8)
                                .padding(.top, 8)
                                .padding(.bottom, 4)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            ForEach(group.items) { item in
                                SidebarRow(
                                    item: item,
                                    isSelected: selectedID == item.id,
                                    highlightQuery: isSearching ? query : nil
                                ) {
                                    selectedID = item.id
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(maxHeight: .infinity)
    }

    private var emptyResults: some View {
        VStack(alignment: .center, spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(DesignColors.textMuted)
            Text("No matches for \"\(query)\"")
                .font(DesignFonts.ui(11.5))
                .foregroundStyle(DesignColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("\(totalCount) transcripts · local")
                .font(DesignFonts.mono(10.5))
                .foregroundStyle(DesignColors.textMuted)
            Spacer()
            Text("● ready")
                .font(DesignFonts.mono(10.5))
                .foregroundStyle(DesignColors.Status.success)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .overlay(
            Rectangle().fill(DesignColors.borderDefault).frame(height: 0.5),
            alignment: .top
        )
    }
}

struct SidebarRow: View {
    let item: SidebarItem
    let isSelected: Bool
    let highlightQuery: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 0) {
                Rectangle()
                    .fill(isSelected ? DesignColors.accentPrimary : Color.clear)
                    .frame(width: 2)

                VStack(alignment: .leading, spacing: 3) {
                    highlightedTitle
                    HStack(spacing: 6) {
                        Text(item.time)
                            .font(DesignFonts.mono(10.5))
                            .foregroundStyle(DesignColors.textSecondary)
                        Text("·")
                            .font(DesignFonts.mono(10.5))
                            .foregroundStyle(DesignColors.textMuted)
                        Text(item.duration)
                            .font(DesignFonts.mono(10.5))
                            .foregroundStyle(DesignColors.textSecondary)
                        Spacer()
                        Text("\(item.speakers)")
                            .font(DesignFonts.ui(9.5))
                            .foregroundStyle(DesignColors.textSecondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(DesignColors.bgTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(.leading, isSelected ? 8 : 10)
                .padding(.trailing, 10)
                .padding(.vertical, 8)
            }
            .background(isSelected ? DesignColors.accentPrimary.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open") { action() }
            Divider()
            Button("Export to Obsidian") {}
            Button("Copy markdown") {}
            Button("Reveal in Finder") {}
            Button("Rename…") {}
            Divider()
            Button(role: .destructive) {} label: { Text("Delete transcript…") }
        }
    }

    @ViewBuilder
    private var highlightedTitle: some View {
        if let query = highlightQuery, !query.isEmpty,
           let range = item.title.range(of: query, options: .caseInsensitive) {
            let before = String(item.title[..<range.lowerBound])
            let match = String(item.title[range])
            let after = String(item.title[range.upperBound...])
            (
                Text(before)
                + Text(match)
                    .foregroundColor(DesignColors.textPrimary)
                    .underline(false)
                    .bold()
                + Text(after)
            )
            .font(DesignFonts.ui(12.5, weight: isSelected ? .semibold : .medium))
            .foregroundStyle(DesignColors.textPrimary)
            .lineLimit(1)
            .truncationMode(.tail)
        } else {
            Text(item.title)
                .font(DesignFonts.ui(12.5, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(DesignColors.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

enum SidebarMockData {
    static let groups: [SidebarGroup] = [
        SidebarGroup(id: "today", label: "Today", items: [
            SidebarItem(id: "t1", title: "Q3 Planning · Eng + Design", duration: "47:12", speakers: 5, time: "11:00 AM"),
            SidebarItem(id: "t2", title: "Daily standup", duration: "14:08", speakers: 4, time: "9:30 AM"),
        ]),
        SidebarGroup(id: "yesterday", label: "Yesterday", items: [
            SidebarItem(id: "t3", title: "Pyannote sidecar review", duration: "32:55", speakers: 3, time: "Wed 4:15 PM"),
            SidebarItem(id: "t4", title: "1:1 with Priya", duration: "28:40", speakers: 2, time: "Wed 2:00 PM"),
        ]),
        SidebarGroup(id: "week", label: "This Week", items: [
            SidebarItem(id: "t5", title: "Customer interview · Acme", duration: "52:01", speakers: 3, time: "Tue 10:00 AM"),
            SidebarItem(id: "t6", title: "WhisperKit benchmark sync", duration: "21:33", speakers: 4, time: "Mon 3:30 PM"),
            SidebarItem(id: "t7", title: "Roadmap rough-cut", duration: "1:04:22", speakers: 6, time: "Mon 11:00 AM"),
        ]),
        SidebarGroup(id: "older", label: "Older", items: [
            SidebarItem(id: "t8", title: "BR-501 design review", duration: "38:14", speakers: 4, time: "May 9"),
            SidebarItem(id: "t9", title: "Series A prep · legal", duration: "46:50", speakers: 3, time: "May 7"),
        ]),
    ]
}

#Preview {
    Sidebar(selectedID: .constant(nil))
        .frame(height: 600)
        .background(DesignColors.bgPrimary)
}
