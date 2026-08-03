//
//  StatsViewModel.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import Foundation

extension TopItemsTimeRange {
    var label: String {
        switch self {
        case .shortTerm: String(localized: "Recent")
        case .mediumTerm: String(localized: "6 Months")
        case .longTerm: String(localized: "All Time")
        }
    }
}

@MainActor
@Observable
final class StatsViewModel {
    var timeRange: TopItemsTimeRange = .shortTerm

    var topTracks: [Track] = []
    var topArtists: [Artist] = []
    var entries: [DiaryEntry] = []

    var recapPeriod: RecapPeriod = .week
    private(set) var recapSnapshots: [TasteSnapshot] = []

    var topItemsErrorMessage: String?
    var entriesErrorMessage: String?
    var isUnauthenticated = false

    private let diaryRepository: DiaryRepositoryProtocol
    private let spotifyRepository: SpotifyRepositoryProtocol
    private let tasteRepository: TasteRepositoryProtocol

    init(
        diaryRepository: DiaryRepositoryProtocol,
        spotifyRepository: SpotifyRepositoryProtocol,
        tasteRepository: TasteRepositoryProtocol
    ) {
        self.diaryRepository = diaryRepository
        self.spotifyRepository = spotifyRepository
        self.tasteRepository = tasteRepository
    }

    func loadEntries() async {
        entriesErrorMessage = nil
        do {
            entries = try await diaryRepository.fetchAllEntries()
        } catch {
            entriesErrorMessage = error.localizedDescription
        }
    }

    func loadRecapSnapshots() async {
        do {
            let from = Calendar.current.date(byAdding: .day, value: -95, to: .now) ?? .now
            recapSnapshots = try await tasteRepository.fetchSnapshots(from: from, to: .now)
        } catch {
            recapSnapshots = []
        }
    }

    var recapState: RecapState {
        RecapCalculator.state(entries: entries, snapshots: recapSnapshots, period: recapPeriod)
    }

    func entries(forTrackID trackID: String) -> [DiaryEntry] {
        entries
            .filter { $0.track?.id == trackID }
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    func entries(forArtistID artistID: String) -> [DiaryEntry] {
        entries
            .filter { entry in
                guard let track = entry.track else { return false }
                return track.artistGroupingKeys.contains { $0.id == artistID }
            }
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    func loadTopItems() async {
        topItemsErrorMessage = nil
        isUnauthenticated = false

        do {
            async let tracks = spotifyRepository.fetchTopTracks(timeRange: timeRange, limit: 10)
            async let artists = spotifyRepository.fetchTopArtists(timeRange: timeRange, limit: 10)
            let (fetchedTracks, fetchedArtists) = try await (tracks, artists)
            topTracks = fetchedTracks
            topArtists = fetchedArtists
            await saveSnapshot(tracks: fetchedTracks, artists: fetchedArtists)
        } catch AuthError.notAuthenticated {
            isUnauthenticated = true
        } catch APIError.unauthorized {
            isUnauthenticated = true
        } catch {
            topItemsErrorMessage = error.localizedDescription
        }
    }

    private func saveSnapshot(tracks: [Track], artists: [Artist]) async {
        _ = try? await TasteSnapshotRefresher.save(tracks: tracks, artists: artists, into: tasteRepository)
    }

    // MARK: - Period window

    private var periodStart: Date? {
        let calendar = Calendar.current
        switch timeRange {
        case .shortTerm: return calendar.date(byAdding: .day, value: -28, to: .now)
        case .mediumTerm: return calendar.date(byAdding: .month, value: -6, to: .now)
        case .longTerm: return nil
        }
    }

    var periodEntries: [DiaryEntry] {
        guard let periodStart else { return entries }
        return entries.filter { $0.loggedAt >= periodStart }
    }

    // MARK: - Summary tiles

    var totalEntryCount: Int { periodEntries.count }

    var distinctTrackCount: Int {
        Set(periodEntries.compactMap { $0.track?.id }).count
    }

    var distinctArtistCount: Int {
        Set(periodEntries.compactMap(\.track).flatMap { $0.artistGroupingKeys.map(\.id) }).count
    }

    // MARK: - Mood distribution

    struct MoodCount: Identifiable {
        let tag: MoodTag
        let count: Int
        var id: MoodTag { tag }
    }

    var moodCounts: [MoodCount] {
        let grouped: [MoodTag: Int] = Dictionary(grouping: periodEntries.flatMap(\.tags)) { $0 }
            .mapValues(\.count)
        let unsorted: [MoodCount] = grouped.map { tag, count in MoodCount(tag: tag, count: count) }
        let sorted: [MoodCount] = unsorted.sorted { lhs, rhs in
            guard lhs.count == rhs.count else { return lhs.count > rhs.count }
            return lhs.tag.label < rhs.tag.label
        }
        return Array(sorted.prefix(8))
    }

    // MARK: - Activity over time

    struct ActivityBucket: Identifiable {
        let date: Date
        let count: Int
        var id: Date { date }
    }

    var activityBucketComponent: Calendar.Component {
        guard let earliest = periodEntries.map(\.loggedAt).min(),
              let latest = periodEntries.map(\.loggedAt).max() else {
            return .day
        }
        let spanDays = Calendar.current.dateComponents([.day], from: earliest, to: latest).day ?? 0
        switch spanDays {
        case ..<31: return .day
        case ..<210: return .weekOfYear
        default: return .month
        }
    }

    var activityBuckets: [ActivityBucket] {
        let calendar = Calendar.current
        let component = activityBucketComponent
        let grouped = Dictionary(grouping: periodEntries) { entry in
            calendar.dateInterval(of: component, for: entry.loggedAt)?.start ?? entry.loggedAt
        }
        return grouped
            .map { ActivityBucket(date: $0.key, count: $0.value.count) }
            .sorted { $0.date < $1.date }
    }

    func activityBucket(at date: Date?) -> ActivityBucket? {
        guard let date else { return nil }
        return activityBuckets.first { $0.date == date }
    }

    func activityBucket(matching tappedDate: Date) -> ActivityBucket? {
        let calendar = Calendar.current
        return activityBuckets.first { bucket in
            guard let bucketEnd = calendar.date(byAdding: activityBucketComponent, value: 1, to: bucket.date) else {
                return false
            }
            return tappedDate >= bucket.date && tappedDate < bucketEnd
        }
    }

    struct GenreCount: Identifiable {
        let genre: String
        let count: Int
        var id: String { genre }
    }

    private(set) var genreBreakdownIsLoading = false
    private var artistGenresCache: [String: [String]] = [:]

    private static let genreStalenessInterval: TimeInterval = 14 * 24 * 60 * 60
    private static let genreFetchSpacingNanoseconds: UInt64 = 150_000_000

    func loadGenreBreakdown() async {
        let artistIds = Set(periodEntries.compactMap(\.track).flatMap { $0.artistGroupingKeys.map(\.id) })
        let unresolvedIds = artistIds.filter { artistGenresCache[$0] == nil }
        guard !unresolvedIds.isEmpty else { return }

        var idsNeedingFetch: [String] = []
        for artistId in unresolvedIds {
            guard let cached = try? await tasteRepository.fetchCachedArtistGenres(id: artistId) else {
                idsNeedingFetch.append(artistId)
                continue
            }
            let isStale = Date().timeIntervalSince(cached.updatedAt) > Self.genreStalenessInterval
            if cached.genres.isEmpty || isStale {
                idsNeedingFetch.append(artistId)
            } else {
                artistGenresCache[artistId] = cached.genres
            }
        }
        guard !idsNeedingFetch.isEmpty else { return }

        genreBreakdownIsLoading = true
        defer { genreBreakdownIsLoading = false }

        for artistId in idsNeedingFetch {
            guard let fetched = try? await spotifyRepository.fetchArtist(id: artistId) else {
                artistGenresCache[artistId] = artistGenresCache[artistId] ?? []
                continue
            }
            _ = try? await tasteRepository.upsertArtist(fetched)
            artistGenresCache[artistId] = fetched.genres
            try? await Task.sleep(nanoseconds: Self.genreFetchSpacingNanoseconds)
        }
    }

    var genreCounts: [GenreCount] {
        var counts: [String: Int] = [:]
        for entry in periodEntries {
            guard let track = entry.track else { continue }
            let genresForEntry = Set(track.artistGroupingKeys.flatMap { artistGenresCache[$0.id] ?? [] })
            for genre in genresForEntry {
                counts[genre, default: 0] += 1
            }
        }
        let sorted = counts.map { GenreCount(genre: $0.key, count: $0.value) }.sorted { lhs, rhs in
            guard lhs.count == rhs.count else { return lhs.count > rhs.count }
            return lhs.genre < rhs.genre
        }
        return Array(sorted.prefix(8))
    }

    var genreAxisTickValues: [Int] {
        axisTickValues(forMax: genreCounts.map(\.count).max() ?? 0)
    }

    var currentStreak: Int {
        StreakCalculator.currentStreak(loggedDates: entries.map(\.loggedAt))
    }

    var longestStreak: Int {
        StreakCalculator.longestStreak(loggedDates: entries.map(\.loggedAt))
    }

    var discoveryRate: Double? {
        let periodArtistIds = Set(periodEntries.compactMap(\.track).flatMap { $0.artistGroupingKeys.map(\.id) })
        guard !periodArtistIds.isEmpty else { return nil }

        var firstAppearance: [String: Date] = [:]
        for entry in entries {
            guard let track = entry.track else { continue }
            for key in track.artistGroupingKeys {
                if let existing = firstAppearance[key.id] {
                    firstAppearance[key.id] = min(existing, entry.loggedAt)
                } else {
                    firstAppearance[key.id] = entry.loggedAt
                }
            }
        }

        let windowStart = periodStart ?? .distantPast
        let newCount = periodArtistIds.filter { (firstAppearance[$0] ?? .distantPast) >= windowStart }.count
        return Double(newCount) / Double(periodArtistIds.count)
    }

    struct ReplayedTrack {
        let track: Track
        let count: Int
    }

    var mostReplayedTrack: ReplayedTrack? {
        let grouped = Dictionary(grouping: periodEntries.compactMap(\.track)) { $0.id }
        let sorted = grouped.values.sorted { lhs, rhs in
            guard lhs.count == rhs.count else { return lhs.count > rhs.count }
            return (lhs.first?.name ?? "") < (rhs.first?.name ?? "")
        }
        guard let topGroup = sorted.first, topGroup.count > 1, let track = topGroup.first else { return nil }
        return ReplayedTrack(track: track, count: topGroup.count)
    }

    var topGenreMood: (genre: String, mood: MoodTag)? {
        guard let topGenre = genreCounts.first?.genre else { return nil }
        let taggedEntries = periodEntries.filter { entry in
            guard let track = entry.track else { return false }
            return track.artistGroupingKeys.contains { artistGenresCache[$0.id]?.contains(topGenre) == true }
        }
        let tagCounts = Dictionary(grouping: taggedEntries.flatMap(\.tags)) { $0 }.mapValues(\.count)
        let sorted = tagCounts.sorted { lhs, rhs in
            guard lhs.value == rhs.value else { return lhs.value > rhs.value }
            return lhs.key.label < rhs.key.label
        }
        guard let topMood = sorted.first?.key else { return nil }
        return (topGenre, topMood)
    }

    var topArtistMismatch: (spotifyTop: Artist, diaryTopName: String, diaryTopCount: Int)? {
        guard let spotifyTop = topArtists.first else { return nil }

        let diaryArtists = periodEntries.compactMap(\.track).flatMap { $0.artistGroupingKeys }
        let diaryCounts = Dictionary(grouping: diaryArtists) { $0.id }.mapValues(\.count)
        let sorted = diaryCounts.sorted { lhs, rhs in
            guard lhs.value == rhs.value else { return lhs.value > rhs.value }
            return lhs.key < rhs.key
        }
        guard let top = sorted.first,
              top.key != spotifyTop.id,
              let diaryTopName = diaryArtists.first(where: { $0.id == top.key })?.name
        else { return nil }

        return (spotifyTop, diaryTopName, top.value)
    }

    struct EngagementMoodRow: Identifiable {
        let level: EngagementLevel
        let count: Int
        var id: EngagementLevel { level }
    }

    var engagementMoodBreakdown: [EngagementMoodRow] {
        EngagementLevel.allCases.compactMap { level in
            let levelEntries = periodEntries.filter { $0.engagementLevel == level }
            guard !levelEntries.isEmpty else { return nil }
            return EngagementMoodRow(level: level, count: levelEntries.count)
        }
    }

    struct HeatmapCell: Identifiable {
        let weekday: Int
        let hourBlockStart: Int
        let count: Int
        var id: String { "\(weekday)-\(hourBlockStart)" }
    }

    static let heatmapHourBlockSize = 4

    var activityHeatmap: [HeatmapCell] {
        let calendar = Calendar.current
        let blockSize = Self.heatmapHourBlockSize
        var counts: [String: Int] = [:]
        for entry in periodEntries {
            let weekday = calendar.component(.weekday, from: entry.playedAt)
            let hour = calendar.component(.hour, from: entry.playedAt)
            let blockStart = (hour / blockSize) * blockSize
            counts["\(weekday)-\(blockStart)", default: 0] += 1
        }
        return (1...7).flatMap { weekday in
            stride(from: 0, to: 24, by: blockSize).map { blockStart in
                HeatmapCell(weekday: weekday, hourBlockStart: blockStart, count: counts["\(weekday)-\(blockStart)"] ?? 0)
            }
        }
    }

    var heatmapMaxCount: Int {
        activityHeatmap.map(\.count).max() ?? 0
    }

    private func axisTickValues(forMax maxCount: Int) -> [Int] {
        guard maxCount > 0 else { return [0] }
        let rawStep = Double(maxCount) / 4
        let magnitude = pow(10, floor(log10(max(rawStep, 1))))
        let normalized = rawStep / magnitude
        let niceNormalized: Double = normalized <= 1 ? 1 : normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10
        let step = max(1, Int(niceNormalized * magnitude))
        return Array(stride(from: 0, through: maxCount, by: step))
    }

    var moodAxisTickValues: [Int] {
        axisTickValues(forMax: moodCounts.map(\.count).max() ?? 0)
    }
}
