//
//  PreviewSupport.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

#if DEBUG

import Foundation
import UIKit

struct PreviewSpotifyRepository: SpotifyRepositoryProtocol {
    var currentlyPlaying: PlaybackResponse<CurrentlyPlayingState> = .active(.preview())
    var profile: UserProfile = .preview
    var recentlyPlayed: [RecentlyPlayedItem] = []
    var topTracks: [Track] = []
    var topArtists: [Artist] = []
    var topItemsFailure: Error?

    func fetchCurrentlyPlaying() async throws -> PlaybackResponse<CurrentlyPlayingState> { currentlyPlaying }
    func fetchRecentlyPlayed(limit: Int, before: Date?) async throws -> [RecentlyPlayedItem] { recentlyPlayed }
    func fetchTopTracks(timeRange: TopItemsTimeRange, limit: Int) async throws -> [Track] {
        if let topItemsFailure { throw topItemsFailure }
        return topTracks
    }
    func fetchTopArtists(timeRange: TopItemsTimeRange, limit: Int) async throws -> [Artist] {
        if let topItemsFailure { throw topItemsFailure }
        return topArtists
    }
    func fetchArtist(id: String) async throws -> Artist {
        Artist(id: id, name: "Preview Artist", popularity: 0, imageURL: nil)
    }
    func searchTracks(query: String, limit: Int, offset: Int) async throws -> [Track] { [] }
    func fetchProfile() async throws -> UserProfile { profile }
    func play() async throws {}
    func pause() async throws {}
}

struct PreviewLoadingSpotifyRepository: SpotifyRepositoryProtocol {
    func fetchCurrentlyPlaying() async throws -> PlaybackResponse<CurrentlyPlayingState> {
        try await Task.sleep(for: .seconds(3600))
        return .noActivePlayback
    }
    func fetchRecentlyPlayed(limit: Int, before: Date?) async throws -> [RecentlyPlayedItem] {
        try await Task.sleep(for: .seconds(3600))
        return []
    }
    func fetchTopTracks(timeRange: TopItemsTimeRange, limit: Int) async throws -> [Track] { [] }
    func fetchTopArtists(timeRange: TopItemsTimeRange, limit: Int) async throws -> [Artist] { [] }
    func fetchArtist(id: String) async throws -> Artist {
        Artist(id: id, name: "Preview Artist", popularity: 0, imageURL: nil)
    }
    func searchTracks(query: String, limit: Int, offset: Int) async throws -> [Track] { [] }
    func fetchProfile() async throws -> UserProfile {
        try await Task.sleep(for: .seconds(3600))
        return .preview
    }
    func play() async throws {}
    func pause() async throws {}
}

actor PreviewDiaryRepository: DiaryRepositoryProtocol {
    private var entries: [UUID: DiaryEntry]

    init(entries: [DiaryEntry] = []) {
        self.entries = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
    }

    func save(_ entry: DiaryEntry) async throws -> DiaryEntry {
        entries[entry.id] = entry
        return entry
    }

    func fetchEntries(from: Date, to: Date) async throws -> [DiaryEntry] {
        entries.values.filter { $0.loggedAt >= from && $0.loggedAt <= to }
    }

    func fetchEntries(forTrackID trackID: String) async throws -> [DiaryEntry] {
        entries.values
            .filter { $0.track?.id == trackID }
            .sorted { ($0.progressMs ?? 0) < ($1.progressMs ?? 0) }
    }

    func fetchAllEntries() async throws -> [DiaryEntry] {
        entries.values.sorted { $0.loggedAt > $1.loggedAt}
    }

    func deleteEntry(id: UUID) async throws {
        entries[id] = nil
    }

    func deleteAllEntries() async throws {
        entries.removeAll()
    }
}

actor PreviewTasteRepository: TasteRepositoryProtocol {
    private var snapshots: [UUID: TasteSnapshot]
    private var artists: [String: Artist] = [:]

    init(snapshots: [TasteSnapshot] = []) {
        self.snapshots = Dictionary(uniqueKeysWithValues: snapshots.map { ($0.id, $0) })
    }

    @discardableResult
    func save(_ snapshot: TasteSnapshot) async throws -> TasteSnapshot {
        snapshots[snapshot.id] = snapshot
        return snapshot
    }

    func fetchSnapshots(from: Date, to: Date) async throws -> [TasteSnapshot] {
        snapshots.values.filter { $0.date >= from && $0.date <= to }
    }

    func fetchLatestSnapshot() async throws -> TasteSnapshot? {
        snapshots.values.sorted { $0.date > $1.date }.first
    }

    func deleteSnapshot(id: UUID) async throws {
        snapshots[id] = nil
    }

    func deleteAllSnapshots() async throws {
        snapshots.removeAll()
    }

    func clearOrphanedCache() async throws {}

    @discardableResult
    func upsertArtist(_ artist: Artist) async throws -> Artist {
        artists[artist.id] = artist
        return artist
    }

    func fetchCachedArtist(id: String) async throws -> Artist? { artists[id] }
}

struct PreviewSpotifyAuthService: SpotifyAuthServiceProtocol {
    var isAuthenticated: Bool { get async { false } }
    func login(windowScene: UIWindowScene) async throws {}
    func logout() throws {}
    func accessToken() async -> String? { nil }
    func refreshAccessToken() async throws -> String { "" }
}

extension UserProfile {
    nonisolated static let preview = UserProfile(
        id: "preview-user",
        displayName: "Дмитрий",
        country: "NG",
        product: .premium,
        imageURL: nil
    )
}

extension Track {
    nonisolated static let preview = Track(
        id: "preview-track",
        name: "A Really Long Song Title That Wraps Onto Two Lines",
        artistNames: ["Preview Artist", "Feat. Someone","Preview Artist", "Feat. Someone","Preview Artist", "Feat. Someone","Preview Artist", "Feat. Someone"],
        albumName: "Preview Album",
        albumImageURL: nil,
        durationMs: 210_000,
        explicit: false,
        uri: "spotify:track:preview"
    )
}

extension Artist {
    nonisolated static let preview = Artist(
        id: "preview-artist",
        name: "Preview Artist",
        popularity: 72,
        imageURL: nil
    )
}

extension CurrentlyPlayingState {
    nonisolated static func preview(progressMs: Int = 45_000, isPlaying: Bool = true) -> CurrentlyPlayingState {
        CurrentlyPlayingState(
            track: .preview,
            isPlaying: isPlaying,
            progressMs: progressMs,
            timestamp: Date(),
            context: nil
        )
    }
}

extension ProfileViewModel {
    static func preview(profile: UserProfile = .preview) -> ProfileViewModel {
        ProfileViewModel(
            repository: PreviewSpotifyRepository(profile: profile),
            diaryRepository: PreviewDiaryRepository(),
            tasteRepository: PreviewTasteRepository()
        )
    }
}

extension RecentlyPlayedItem {
    nonisolated static func preview(name: String = "Preview Track", minutesAgo: Double = 5) -> RecentlyPlayedItem {
        RecentlyPlayedItem(
            track: Track(
                id: "preview-track-\(name)",
                name: name,
                artistNames: ["Preview Artist"],
                albumName: "Preview Album",
                albumImageURL: nil,
                durationMs: 210_000,
                explicit: false,
                uri: "spotify:track:preview"
            ),
            playedAt: Date().addingTimeInterval(-minutesAgo * 60),
            context: nil
        )
    }
}

private nonisolated func previewTrack(trackName: String, artistName: String) -> Track {
    Track(
        id: "preview-track-\(trackName)",
        name: trackName,
        artistNames: [artistName],
        artistIds: ["preview-artist-\(artistName)"],
        albumName: "Preview Album",
        albumImageURL: nil,
        durationMs: 210_000,
        explicit: false,
        uri: "spotify:track:preview"
    )
}

private nonisolated let previewStatsTrackPool: [(track: String, artist: String)] = [
    ("Nightcall", "Kavinsky"), ("Midnight City", "M83"), ("Champion", "Fred Again.."),
    ("Holocene", "Bon Iver"), ("Electric Feel", "MGMT"), ("Yellow", "Coldplay"),
    ("Good Days", "SZA"), ("Bloom", "The Paper Kites"), ("Weightless", "Marconi Union"),
    ("Redbone", "Childish Gambino")
]

extension Track {
    nonisolated static let previewStatsList: [Track] = previewStatsTrackPool.map {
        previewTrack(trackName: $0.track, artistName: $0.artist)
    }
}

extension Artist {
    nonisolated static let previewStatsList: [Artist] = previewStatsTrackPool.enumerated().map { index, entry in
        Artist(id: "preview-artist-\(entry.artist)", name: entry.artist, popularity: 90 - index * 5, imageURL: nil)
    }
}

extension DiaryEntry {
    nonisolated static func reaction(
        trackName: String,
        tag: MoodTag,
        hoursAgo: Double,
        progressMs: Int = 45_000,
        artistName: String = "Preview Artist"
    ) -> DiaryEntry {
        DiaryEntry(
            id: UUID(),
            loggedAt: Date().addingTimeInterval(-hoursAgo * 3600),
            playedAt: Date().addingTimeInterval(-hoursAgo * 3600),
            engagementLevel: .quickTap,
            tags: [tag],
            title: nil,
            note: nil,
            progressMs: progressMs,
            track: previewTrack(trackName: trackName, artistName: artistName)
        )
    }

    nonisolated static func detailedEntry(
        title: String,
        trackName: String,
        note: String? = nil,
        hoursAgo: Double,
        progressMs: Int = 45_000,
        artistName: String = "Preview Artist"
    ) -> DiaryEntry {
        DiaryEntry(
            id: UUID(),
            loggedAt: Date().addingTimeInterval(-hoursAgo * 3600),
            playedAt: Date().addingTimeInterval(-hoursAgo * 3600),
            engagementLevel: .detailed,
            tags: [],
            title: title,
            note: note,
            progressMs: progressMs,
            track: previewTrack(trackName: trackName, artistName: artistName)
        )
    }

    nonisolated static let previewList: [DiaryEntry] = [
        .detailedEntry(title: "Late night drive", trackName: "Nightcall", note: "Windows down, empty highway.", hoursAgo: 2, artistName: "Kavinsky"),
        .reaction(trackName: "Midnight City", tag: .energetic, hoursAgo: 5, artistName: "M83"),
        .reaction(trackName: "Champion", tag: .confident, hoursAgo: 9),
        .detailedEntry(title: "Rainy Sunday", trackName: "Holocene", note: "Coffee, rain, this song on repeat.", hoursAgo: 26),
        .reaction(trackName: "Electric Feel that is extremely long by DJ KHALED GOD DID", tag: .dreamy, hoursAgo: 30),
        .detailedEntry(title: "Gym session", trackName: "Till I Collapse", note: "New PR on deadlifts.", hoursAgo: 48),
        .reaction(trackName: "Yellow", tag: .peaceful, hoursAgo: 55),
        .detailedEntry(title: "Breakup week", trackName: "Someone Like You", note: "Still stings a little.", hoursAgo: 72),
        .reaction(trackName: "Good Days", tag: .hopeful, hoursAgo: 96, artistName: "M83"),
        .detailedEntry(title: "First listen", trackName: "Bloom", note: "New album dropped today, love it already.", hoursAgo: 120)
    ]

    nonisolated static var previewStatsScenario: [DiaryEntry] {
        let tags: [MoodTag] = [.happy, .energetic, .calm, .melancholic, .focused, .nostalgic, .hopeful, .peaceful, .anxious, .grateful]

        func burstEntries(count: Int, daysAgoRange: ClosedRange<Int>) -> [DiaryEntry] {
            var entries: [DiaryEntry] = []
            var remaining = count
            var poolIndex = 0
            var tagIndex = 0
            while remaining > 0 {
                let day = Int.random(in: daysAgoRange)
                let burst = (Int.random(in: 0..<4) == 0 && remaining > 2) ? Int.random(in: 2...4) : 1
                let actualBurst = min(burst, remaining)
                for offset in 0..<actualBurst {
                    let pool = previewStatsTrackPool[poolIndex % previewStatsTrackPool.count]
                    let tag = tags[tagIndex % tags.count]
                    poolIndex += 1
                    tagIndex += 1
                    entries.append(.reaction(
                        trackName: pool.track,
                        tag: tag,
                        hoursAgo: Double(day * 24 + offset * 2),
                        artistName: pool.artist
                    ))
                }
                remaining -= actualBurst
            }
            return entries
        }

        return burstEntries(count: 10, daysAgoRange: 29...182) + burstEntries(count: 30, daysAgoRange: 183...400)
    }

    nonisolated static let previewEntriesForCurrentTrack: [DiaryEntry] = [
        DiaryEntry(
            id: UUID(),
            loggedAt: Date().addingTimeInterval(-3600),
            playedAt: Date().addingTimeInterval(-3600),
            engagementLevel: .quickTap,
            tags: [.energetic],
            title: nil,
            note: nil,
            progressMs: 20_000,
            track: .preview
        ),
        DiaryEntry(
            id: UUID(),
            loggedAt: Date().addingTimeInterval(-7200),
            playedAt: Date().addingTimeInterval(-7200),
            engagementLevel: .detailed,
            tags: [],
            title: "Great hook",
            note: "Loved the bridge on this one.",
            progressMs: 95_000,
            track: .preview
        )
    ]
}

// MARK: - Recap sample data

enum RecapPreviewScenario {
    case full
    case noHistory
    case sparse
}

enum RecapSampleData {
    static func generate(scenario: RecapPreviewScenario, now: Date = .now) -> (entries: [DiaryEntry], snapshots: [TasteSnapshot]) {
        let calendar = Calendar.current
        let tags: [MoodTag] = [.happy, .energetic, .calm, .melancholic, .focused, .nostalgic, .hopeful, .peaceful, .anxious, .grateful]

        func makeEntry(daysAgo: Int, hourOffset: Int, poolIndex: Int, tagIndex: Int) -> DiaryEntry {
            let pool = previewStatsTrackPool[poolIndex % previewStatsTrackPool.count]
            let tag = tags[tagIndex % tags.count]
            let date = calendar.date(byAdding: .hour, value: -(daysAgo * 24 + hourOffset), to: now) ?? now
            return DiaryEntry(
                id: UUID(),
                loggedAt: date,
                playedAt: date,
                engagementLevel: .quickTap,
                tags: [tag],
                title: nil,
                note: nil,
                progressMs: 45_000,
                track: previewTrack(trackName: pool.track, artistName: pool.artist)
            )
        }

        func makeSnapshot(daysAgo: Int, trackOrder: [Int], artistOrder: [Int]) -> TasteSnapshot {
            TasteSnapshot(
                id: UUID(),
                date: calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now,
                trackEntries: trackOrder.enumerated().map { rank, poolIndex in
                    TasteSnapshotTrackEntry(rank: rank + 1, track: Track.previewStatsList[poolIndex % Track.previewStatsList.count])
                },
                artistEntries: artistOrder.enumerated().map { rank, poolIndex in
                    TasteSnapshotArtistEntry(rank: rank + 1, artist: Artist.previewStatsList[poolIndex % Artist.previewStatsList.count])
                }
            )
        }

        switch scenario {
        case .full:
            var entries: [DiaryEntry] = []
            var poolIndex = 0
            var tagIndex = 0

            for (day, burst) in [4, 3, 4, 3, 4].enumerated() {
                for offset in 0..<burst {
                    entries.append(makeEntry(daysAgo: day, hourOffset: offset * 3, poolIndex: poolIndex, tagIndex: tagIndex))
                    poolIndex += 1
                    tagIndex += 1
                }
            }

            for day in stride(from: 10, to: 90, by: 4) {
                entries.append(makeEntry(daysAgo: day, hourOffset: 0, poolIndex: poolIndex, tagIndex: tagIndex))
                poolIndex += 1
                tagIndex += 1
            }

            let snapshots = [
                makeSnapshot(daysAgo: 0, trackOrder: [1, 0, 3, 4, 2], artistOrder: [1, 0, 3, 4, 2]),
                makeSnapshot(daysAgo: 8, trackOrder: [0, 5, 6, 7, 1], artistOrder: [0, 5, 6, 7, 1])
            ]
            return (entries, snapshots)

        case .noHistory:
            var entries: [DiaryEntry] = []
            var poolIndex = 0
            var tagIndex = 0
            for (day, burst) in [3, 2, 3, 2, 3].enumerated() {
                for offset in 0..<burst {
                    entries.append(makeEntry(daysAgo: day, hourOffset: offset * 3, poolIndex: poolIndex, tagIndex: tagIndex))
                    poolIndex += 1
                    tagIndex += 1
                }
            }
            let snapshots = [makeSnapshot(daysAgo: 0, trackOrder: [0, 1, 2], artistOrder: [0, 1, 2])]
            return (entries, snapshots)

        case .sparse:
            let entries = [
                makeEntry(daysAgo: 0, hourOffset: 0, poolIndex: 0, tagIndex: 0),
                makeEntry(daysAgo: 1, hourOffset: 0, poolIndex: 1, tagIndex: 1)
            ]
            return (entries, [])
        }
    }
}

extension StatsViewModel {
    static func previewRecap(scenario: RecapPreviewScenario) -> StatsViewModel {
        let data = RecapSampleData.generate(scenario: scenario)
        return StatsViewModel(
            diaryRepository: PreviewDiaryRepository(entries: data.entries),
            spotifyRepository: PreviewSpotifyRepository(topTracks: Track.previewStatsList, topArtists: Artist.previewStatsList),
            tasteRepository: PreviewTasteRepository(snapshots: data.snapshots)
        )
    }

    static func previewRecapFull() -> StatsViewModel { previewRecap(scenario: .full) }
    static func previewRecapNoHistory() -> StatsViewModel { previewRecap(scenario: .noHistory) }
    static func previewRecapSparse() -> StatsViewModel { previewRecap(scenario: .sparse) }
}

extension DiaryViewModel {
    static func preview(entries: [DiaryEntry] = DiaryEntry.previewList) -> DiaryViewModel {
        DiaryViewModel(
            diaryRepository: PreviewDiaryRepository(entries: entries),
            spotifyRepository: PreviewSpotifyRepository(),
            tasteRepository: PreviewTasteRepository()
        )
    }

    static func previewEmpty() -> DiaryViewModel {
        DiaryViewModel(
            diaryRepository: PreviewDiaryRepository(),
            spotifyRepository: PreviewSpotifyRepository(),
            tasteRepository: PreviewTasteRepository()
        )
    }
}

extension StatsViewModel {
    static func preview(entries: [DiaryEntry] = DiaryEntry.previewStatsScenario) -> StatsViewModel {
        StatsViewModel(
            diaryRepository: PreviewDiaryRepository(entries: entries),
            spotifyRepository: PreviewSpotifyRepository(topTracks: Track.previewStatsList, topArtists: Artist.previewStatsList),
            tasteRepository: PreviewTasteRepository()
        )
    }

    static func previewEmpty() -> StatsViewModel {
        StatsViewModel(
            diaryRepository: PreviewDiaryRepository(),
            spotifyRepository: PreviewSpotifyRepository(),
            tasteRepository: PreviewTasteRepository()
        )
    }

    static func previewUnauthenticated() -> StatsViewModel {
        StatsViewModel(
            diaryRepository: PreviewDiaryRepository(entries: DiaryEntry.previewList),
            spotifyRepository: PreviewSpotifyRepository(topItemsFailure: AuthError.notAuthenticated),
            tasteRepository: PreviewTasteRepository()
        )
    }
}

extension LogViewModel {
    static func preview(recentlyPlayed: [RecentlyPlayedItem] = [.preview(name: "Song One", minutesAgo: 5), .preview(name: "Song Two", minutesAgo: 40), .preview(name: "Song Three", minutesAgo: 120)]) -> LogViewModel {
        LogViewModel(repository: PreviewSpotifyRepository(recentlyPlayed: recentlyPlayed), diaryRepository: PreviewDiaryRepository())
    }

    static func previewEmpty() -> LogViewModel {
        LogViewModel(repository: PreviewSpotifyRepository(recentlyPlayed: []), diaryRepository: PreviewDiaryRepository())
    }

    static func previewLoading() -> LogViewModel {
        LogViewModel(repository: PreviewLoadingSpotifyRepository(), diaryRepository: PreviewDiaryRepository())
    }
}

extension PlayerViewModel {
    static func preview(
        currentlyPlaying: PlaybackResponse<CurrentlyPlayingState> = .active(.preview()),
        diaryEntries: [DiaryEntry] = DiaryEntry.previewEntriesForCurrentTrack
    ) -> PlayerViewModel {
        PlayerViewModel(
            repository: PreviewSpotifyRepository(currentlyPlaying: currentlyPlaying, profile: .preview),
            diaryRepository: PreviewDiaryRepository(entries: diaryEntries),
            initialState: currentlyPlaying
        )
    }

    static func previewLoading() -> PlayerViewModel {
        PlayerViewModel(
            repository: PreviewLoadingSpotifyRepository(),
            diaryRepository: PreviewDiaryRepository()
        )
    }
}

#endif
