//
//  DiaryViewModel.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 26.07.2026.
//

import Foundation

@MainActor
@Observable
final class DiaryViewModel {
    var entries: [DiaryEntry] = []
    var isLoading = false
    var errorMessage: String?
    var deleteErrorMessage: String?

    var searchText = ""
    var browseMode: DiaryBrowseMode = .entries
    var groupByDay = false
    var filter = DiaryFilter()

    private(set) var sortField: DiarySortField = .date
    private(set) var sortDirection: DiarySortDirection = .descending

    private let diaryRepository: DiaryRepositoryProtocol
    private let spotifyRepository: SpotifyRepositoryProtocol
    private let tasteRepository: TasteRepositoryProtocol

    private var fetchedArtistImageURLs: [String: URL] = [:]
    private var queuedArtistImageIds: Set<String> = []
    private var artistImageQueue: [String] = []
    private var isProcessingArtistImageQueue = false

    private static let artistImageFetchSpacingNanoseconds: UInt64 = 150_000_000

    init(
        diaryRepository: DiaryRepositoryProtocol,
        spotifyRepository: SpotifyRepositoryProtocol,
        tasteRepository: TasteRepositoryProtocol
    ) {
        self.diaryRepository = diaryRepository
        self.spotifyRepository = spotifyRepository
        self.tasteRepository = tasteRepository
    }

    // MARK: - Loading & deletion

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            entries = try await diaryRepository.fetchAllEntries()
        } catch {
            if !error.isCancellation {
                errorMessage = error.localizedDescription
            }
        }
    }

    func delete(_ entry: DiaryEntry) async {
        entries.removeAll { $0.id == entry.id }

        do {
            try await diaryRepository.deleteEntry(id: entry.id)
        } catch {
            if !error.isCancellation {
                deleteErrorMessage = error.localizedDescription
            }
            if let restored = try? await diaryRepository.fetchAllEntries() {
                entries = restored
            }
        }
    }

    // MARK: - Browse mode / sort

    var effectiveSortField: DiarySortField {
        DiarySortField.availableFields(for: browseMode).contains(sortField) ? sortField : .date
    }

    func setSortField(_ field: DiarySortField) {
        guard field != sortField else { return }
        sortField = field
        sortDirection = field.defaultDirection
    }

    func toggleSortDirection() {
        sortDirection = sortDirection.toggled
    }

    // MARK: - Filtering pipeline: search -> filter -> sort/group

    private var searchFilteredEntries: [DiaryEntry] {
        guard !searchText.isEmpty else { return entries }
        let query = searchText.lowercased()
        return entries.filter { entry in
            if let title = entry.title, title.lowercased().contains(query) { return true }
            if let note = entry.note, note.lowercased().contains(query) { return true }
            if let track = entry.track {
                if track.name.lowercased().contains(query) { return true }
                if track.artistNames.contains(where: { $0.lowercased().contains(query) }) { return true }
            }
            return false
        }
    }

    var filteredEntries: [DiaryEntry] {
        searchFilteredEntries.filter(filter.matches)
    }

    var sortedEntries: [DiaryEntry] {
        let ascending = filteredEntries.sorted { $0.loggedAt < $1.loggedAt }
        return sortDirection == .ascending ? ascending : ascending.reversed()
    }

    struct DaySection: Identifiable {
        let id: Date
        let entries: [DiaryEntry]
    }

    var entriesGroupedByDay: [DaySection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sortedEntries) { calendar.startOfDay(for: $0.loggedAt) }
        let orderedDays = sortDirection == .ascending
            ? grouped.keys.sorted()
            : grouped.keys.sorted(by: >)
        return orderedDays.map { day in
            DaySection(id: day, entries: grouped[day] ?? [])
        }
    }

    private var entriesWithTrack: [DiaryEntry] {
        filteredEntries.filter { $0.track != nil }
    }

    // MARK: - Track/Artist summaries

    var trackSummaries: [DiaryTrackSummary] {
        let grouped = Dictionary(grouping: entriesWithTrack) { $0.track!.id }
        let summaries = grouped.values.compactMap { groupedEntries -> DiaryTrackSummary? in
            guard let track = groupedEntries.first?.track else { return nil }
            return DiaryTrackSummary(track: track, entries: groupedEntries)
        }
        return sortedSummaries(summaries)
    }

    var artistSummaries: [DiaryArtistSummary] {
        var grouped: [String: (name: String, entries: [DiaryEntry])] = [:]
        for entry in entriesWithTrack {
            for key in entry.track!.artistGroupingKeys {
                grouped[key.id, default: (key.name, [])].entries.append(entry)
            }
        }
        let summaries = grouped.map { artistId, value in
            DiaryArtistSummary(
                artistId: artistId,
                artistName: value.name,
                entries: value.entries,
                fetchedImageURL: fetchedArtistImageURLs[artistId]
            )
        }
        return sortedSummaries(summaries)
    }

    // MARK: - Artist photo enrichment

    func fetchArtistImageIfNeeded(for summary: DiaryArtistSummary) async {
        guard summary.imageURL == nil, summary.hasResolvableArtistId else { return }
        let artistId = summary.artistId
        guard !queuedArtistImageIds.contains(artistId) else { return }

        if let cached = try? await tasteRepository.fetchCachedArtist(id: artistId), let imageURL = cached.imageURL {
            fetchedArtistImageURLs[artistId] = imageURL
            return
        }

        queuedArtistImageIds.insert(artistId)
        artistImageQueue.append(artistId)
        await processArtistImageQueueIfNeeded()
    }

    private func processArtistImageQueueIfNeeded() async {
        guard !isProcessingArtistImageQueue else { return }
        isProcessingArtistImageQueue = true
        defer { isProcessingArtistImageQueue = false }

        while !artistImageQueue.isEmpty {
            let artistId = artistImageQueue.removeFirst()
            defer { queuedArtistImageIds.remove(artistId) }

            do {
                let artist = try await spotifyRepository.fetchArtist(id: artistId)
                try await tasteRepository.upsertArtist(artist)
                if let imageURL = artist.imageURL {
                    fetchedArtistImageURLs[artistId] = imageURL
                }
            } catch {
                // failed fetch just leaves the placeholder icon
            }

            try? await Task.sleep(nanoseconds: Self.artistImageFetchSpacingNanoseconds)
        }
    }

    // MARK: - Drill-down entries

    func entries(forTrackID trackID: String) -> [DiaryEntry] {
        filteredEntries
            .filter { $0.track?.id == trackID }
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    func entries(forArtistID artistID: String) -> [DiaryEntry] {
        filteredEntries
            .filter { entry in
                guard let track = entry.track else { return false }
                return track.artistGroupingKeys.contains { $0.id == artistID }
            }
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    // MARK: - Summary sorting

    private func sortedSummaries<S: DiarySummary>(_ summaries: [S]) -> [S] {
        summaries.sorted { lhs, rhs in
            let primary = primaryOrder(lhs, rhs)
            if primary != .orderedSame {
                return sortDirection == .ascending ? primary == .orderedAscending : primary == .orderedDescending
            }
            let byName = lhs.sortName.localizedCaseInsensitiveCompare(rhs.sortName)
            if byName != .orderedSame { return byName == .orderedAscending }
            return lhs.id < rhs.id
        }
    }

    private func primaryOrder<S: DiarySummary>(_ lhs: S, _ rhs: S) -> ComparisonResult {
        switch effectiveSortField {
        case .date:
            if lhs.lastLoggedAt == rhs.lastLoggedAt { return .orderedSame }
            return lhs.lastLoggedAt < rhs.lastLoggedAt ? .orderedAscending : .orderedDescending
        case .count:
            if lhs.entryCount == rhs.entryCount { return .orderedSame }
            return lhs.entryCount < rhs.entryCount ? .orderedAscending : .orderedDescending
        case .name:
            return lhs.sortName.localizedCaseInsensitiveCompare(rhs.sortName)
        }
    }
}
