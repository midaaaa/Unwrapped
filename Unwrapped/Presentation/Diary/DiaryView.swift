//
//  DiaryView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import SwiftUI

struct DiaryView: View {
    @Bindable var viewModel: DiaryViewModel
    var profileImageURL: URL?
    let namespace: Namespace.ID
    var onProfileTap: () -> Void = {}
    var onEntryTap: (DiaryEntry) -> Void = { _ in }

    @State private var scopedTarget: DiaryScope?
    @State private var showMoodTagFilter = false
    @State private var showDateRangeFilter = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Diary")
                .searchable(text: $viewModel.searchText, prompt: "Search entries")
                .toolbar {
                    if !viewModel.entries.isEmpty {
                        ToolbarItem(placement: .topBarLeading) {
                            viewMenu
                        }
                        ToolbarItem(placement: .topBarLeading) {
                            filterMenu
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        ProfileAvatarButton(imageURL: profileImageURL, onTap: onProfileTap)
                    }
                }
                .navigationDestination(item: $scopedTarget) { target in
                    DiaryScopedEntriesView(
                        title: target.title,
                        entries: target.entries(in: viewModel),
                        namespace: namespace,
                        onEntryTap: onEntryTap,
                        onDelete: { await viewModel.delete($0) }
                    )
                }
                .sheet(isPresented: $showMoodTagFilter) {
                    DiaryMoodTagFilterSheet(selectedTags: $viewModel.filter.moodTags)
                }
                .sheet(isPresented: $showDateRangeFilter) {
                    DiaryDateRangeFilterSheet(dateRange: $viewModel.filter.dateRange)
                }
                .task {
                    await viewModel.load()
                }
                .errorAlert("Couldn't Delete Entry", message: $viewModel.deleteErrorMessage)
        }
    }

    // MARK: - Toolbar menus

    private var viewMenu: some View {
        Menu {
            Picker("View", selection: $viewModel.browseMode) {
                ForEach(DiaryBrowseMode.allCases, id: \.self) { mode in
                    Label(mode.label, systemImage: mode.systemImage).tag(mode)
                }
            }

            if viewModel.browseMode == .entries {
                Toggle(isOn: $viewModel.groupByDay) {
                    Label("Group by Day", systemImage: "calendar.day.timeline.left")
                }
            }

            Section("Sort By") {
                let availableFields = DiarySortField.availableFields(for: viewModel.browseMode)
                if availableFields.count > 1 {
                    Picker("Sort By", selection: sortFieldBinding) {
                        ForEach(availableFields, id: \.self) { field in
                            Text(field.label).tag(field)
                        }
                    }
                }

                Button {
                    viewModel.toggleSortDirection()
                } label: {
                    Label(
                        viewModel.sortDirection.label(for: viewModel.effectiveSortField),
                        systemImage: viewModel.sortDirection.systemImage
                    )
                }
            }
        } label: {
            Image(systemName: viewModel.browseMode.systemImage)
        }
        .menuIndicator(.hidden)
    }

    private var sortFieldBinding: Binding<DiarySortField> {
        Binding(
            get: { viewModel.effectiveSortField },
            set: { viewModel.setSortField($0) }
        )
    }

    private var filterMenu: some View {
        Menu {
            Toggle(isOn: kindBinding(.quickTap)) {
                Label("Reactions", systemImage: "sparkles")
            }
            Toggle(isOn: kindBinding(.detailed)) {
                Label("Detailed Entries", systemImage: "text.bubble")
            }

            Toggle(isOn: moodTagsActiveBinding) {
                Label("Mood Tags…", systemImage: "face.smiling")
            }
            .disabled(!viewModel.filter.kinds.contains(.quickTap))

            Toggle(isOn: dateRangeActiveBinding) {
                Label("Date Range…", systemImage: "calendar")
            }

            if viewModel.filter.isActive {
                Divider()
                Button(role: .destructive) {
                    viewModel.filter = DiaryFilter()
                } label: {
                    Label("Clear Filters", systemImage: "xmark.circle")
                }
            }
        } label: {
            Image(systemName: viewModel.filter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease")
        }
        .menuIndicator(.hidden)
    }

    private func kindBinding(_ kind: EngagementLevel) -> Binding<Bool> {
        Binding(
            get: { viewModel.filter.kinds.contains(kind) },
            set: { isOn in
                if isOn {
                    viewModel.filter.kinds.insert(kind)
                } else {
                    viewModel.filter.kinds.remove(kind)
                }
            }
        )
    }

    private var moodTagsActiveBinding: Binding<Bool> {
        Binding(
            get: { !viewModel.filter.moodTags.isEmpty },
            set: { _ in showMoodTagFilter = true }
        )
    }

    private var dateRangeActiveBinding: Binding<Bool> {
        Binding(
            get: { viewModel.filter.dateRange != nil },
            set: { _ in showDateRangeFilter = true }
        )
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.entries.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                switch viewModel.browseMode {
                case .entries:
                    entriesContent
                case .tracks:
                    tracksContent
                case .artists:
                    artistsContent
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private var entriesContent: some View {
        if let errorMessage = viewModel.errorMessage, viewModel.entries.isEmpty {
            EmptyStateRow(
                title: "Couldn't load diary",
                systemImage: "exclamationmark.triangle",
                description: Text(errorMessage)
            )
        } else if viewModel.entries.isEmpty {
            noDataYetState
        } else {
            let sorted = viewModel.sortedEntries
            if sorted.isEmpty {
                EmptyStateRow(
                    title: "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No entries match the current search and filters.")
                )
            } else if viewModel.groupByDay {
                ForEach(viewModel.entriesGroupedByDay) { section in
                    Section {
                        ForEach(section.entries) { entry in entryRow(entry) }
                    } header: {
                        if Calendar.current.isDateInToday(section.id) {
                            Text("Today")
                        } else if Calendar.current.isDateInYesterday(section.id) {
                            Text("Yesterday")
                        } else if Calendar.current.isDate(section.id, equalTo: .now, toGranularity: .year) {
                            Text(section.id.formatted(.dateTime.day().month(.wide)))
                        } else {
                            Text(section.id.formatted(.dateTime.day().month(.wide).year()))
                        }
                    }
                    .listSectionSeparator(.hidden, edges: [.top, .bottom])
                }
            } else {
                ForEach(sorted) { entry in
                    entryRow(entry)
                        .listSectionSeparator(.hidden, edges: [.top, .bottom])
                }
            }
        }
    }

    private var noDataYetState: some View {
        EmptyStateRow(
            title: "Nothing here yet",
            systemImage: "book.closed",
            description: Text("Entries you log will show up here.")
        )
    }

    @ViewBuilder
    private var tracksContent: some View {
        summaryContent(
            viewModel.trackSummaries,
            noResultsDescription: String(localized: "No tracks match the current search and filters.")
        ) { summary in
            DiaryTrackRow(summary: summary, onTap: { scopedTarget = .track(id: summary.track.id, name: summary.track.name) })
                .spotifyDeepLinkSwipeAction(trackID: summary.track.id, isCompact: true)
        }
    }

    @ViewBuilder
    private var artistsContent: some View {
        summaryContent(
            viewModel.artistSummaries,
            noResultsDescription: String(localized: "No artists match the current search and filters.")
        ) { summary in
            DiaryArtistRow(
                summary: summary,
                onTap: { scopedTarget = .artist(id: summary.artistId, name: summary.artistName) },
                fetchImageIfNeeded: { await viewModel.fetchArtistImageIfNeeded(for: $0) }
            )
        }
    }

    @ViewBuilder
    private func summaryContent<S: DiarySummary & Identifiable, RowContent: View>(
        _ summaries: [S],
        noResultsDescription: String,
        @ViewBuilder row: @escaping (S) -> RowContent
    ) -> some View {
        if viewModel.entries.isEmpty {
            noDataYetState
        } else if summaries.isEmpty {
            EmptyStateRow(
                title: "No Results",
                systemImage: "magnifyingglass",
                description: Text(noResultsDescription)
            )
        } else {
            ForEach(summaries) { summary in
                row(summary)
                    .listSectionSeparator(.hidden, edges: [.top, .bottom])
            }
        }
    }

    private func entryRow(_ entry: DiaryEntry) -> some View {
        DiaryEntryRow(entry: entry, namespace: namespace, onTap: { onEntryTap(entry) })
            .diaryEntrySwipeActions(entry: entry, isCompact: true) {
                Task { await viewModel.delete(entry) }
            }
    }
}

private enum DiaryScope: Identifiable, Hashable {
    case track(id: String, name: String)
    case artist(id: String, name: String)

    var id: String {
        switch self {
        case .track(let id, _): "track:\(id)"
        case .artist(let id, _): "artist:\(id)"
        }
    }

    var title: String {
        switch self {
        case .track(_, let name): name
        case .artist(_, let name): name
        }
    }

    func entries(in viewModel: DiaryViewModel) -> [DiaryEntry] {
        switch self {
        case .track(let id, _): viewModel.entries(forTrackID: id)
        case .artist(let id, _): viewModel.entries(forArtistID: id)
        }
    }
}

#if DEBUG
private struct DiaryPreviewContainer: View {
    let viewModel: DiaryViewModel
    @State private var showProfile = false
    @Namespace private var namespace

    var body: some View {
        DiaryView(viewModel: viewModel, namespace: namespace, onProfileTap: { showProfile = true })
            .sheet(isPresented: $showProfile) {
                ProfileView(viewModel: .preview(), onLogout: {})
            }
    }
}

#Preview("With items") {
    DiaryPreviewContainer(viewModel: .preview())
}

#Preview("Empty") {
    DiaryPreviewContainer(viewModel: .previewEmpty())
}
#endif
