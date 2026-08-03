//
//  StatsViewModelTests.swift
//  UnwrappedTests
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import XCTest
@testable import Unwrapped

@MainActor
final class StatsViewModelTests: XCTestCase {
    private let calendar = Calendar.current

    private func daysAgo(_ days: Int, from now: Date = Date()) -> Date {
        calendar.date(byAdding: .day, value: -days, to: now)!
    }

    private func track(id: String, name: String = "Song", artistId: String = "a1", artistName: String = "Artist") -> Track {
        Track(
            id: id,
            name: name,
            artistNames: [artistName],
            artistIds: [artistId],
            albumName: "Album",
            durationMs: 200_000,
            explicit: false,
            uri: "spotify:track:\(id)"
        )
    }

    private func artist(id: String, name: String = "Artist") -> Artist {
        Artist(id: id, name: name, genres: [], popularity: 0, imageURL: nil)
    }

    private func entry(
        loggedAt: Date,
        playedAt: Date? = nil,
        track: Track? = nil,
        tags: [MoodTag] = [],
        engagementLevel: EngagementLevel = .quickTap
    ) -> DiaryEntry {
        DiaryEntry(
            id: UUID(),
            loggedAt: loggedAt,
            playedAt: playedAt ?? loggedAt,
            engagementLevel: engagementLevel,
            tags: tags,
            title: nil,
            note: nil,
            progressMs: nil,
            track: track
        )
    }

    private func makeViewModel(entries: [DiaryEntry] = [], topArtists: [Artist] = []) -> StatsViewModel {
        let vm = StatsViewModel(
            diaryRepository: FakeDiaryRepository(),
            spotifyRepository: FakeSpotifyRepository(),
            tasteRepository: FakeTasteRepository()
        )
        vm.entries = entries
        vm.topArtists = topArtists
        return vm
    }

    // MARK: - periodEntries window

    func test_periodEntries_shortTerm_excludesEntriesOlderThan28Days() {
        let now = Date()
        let recent = entry(loggedAt: daysAgo(10, from: now))
        let old = entry(loggedAt: daysAgo(40, from: now))
        let vm = makeViewModel(entries: [recent, old])
        vm.timeRange = .shortTerm

        XCTAssertEqual(vm.periodEntries.map(\.id), [recent.id])
    }

    func test_periodEntries_longTerm_includesEverything() {
        let old = entry(loggedAt: daysAgo(400))
        let vm = makeViewModel(entries: [old])
        vm.timeRange = .longTerm

        XCTAssertEqual(vm.periodEntries.map(\.id), [old.id])
    }

    // MARK: - Mood distribution

    func test_moodCounts_sortsByCountThenLabelAndCapsAtEight() {
        let now = Date()
        var entries: [DiaryEntry] = []
        for _ in 0..<3 { entries.append(entry(loggedAt: now, tags: [.happy])) }
        for _ in 0..<5 { entries.append(entry(loggedAt: now, tags: [.sad])) }
        let vm = makeViewModel(entries: entries)

        let counts = vm.moodCounts
        XCTAssertEqual(counts.map(\.tag), [.sad, .happy])
        XCTAssertEqual(counts.map(\.count), [5, 3])
    }

    // MARK: - Activity bucketing

    func test_activityBucketComponent_shortSpan_usesDay() {
        let now = Date()
        let vm = makeViewModel(entries: [entry(loggedAt: now), entry(loggedAt: daysAgo(5, from: now))])
        XCTAssertEqual(vm.activityBucketComponent, .day)
    }

    func test_activityBucketComponent_mediumSpan_usesWeek() {
        let now = Date()
        let vm = makeViewModel(entries: [entry(loggedAt: now), entry(loggedAt: daysAgo(60, from: now))])
        vm.timeRange = .longTerm
        XCTAssertEqual(vm.activityBucketComponent, .weekOfYear)
    }

    func test_activityBucketComponent_longSpan_usesMonth() {
        let now = Date()
        let vm = makeViewModel(entries: [entry(loggedAt: now), entry(loggedAt: daysAgo(300, from: now))])
        vm.timeRange = .longTerm
        XCTAssertEqual(vm.activityBucketComponent, .month)
    }

    func test_activityBuckets_groupsEntriesIntoSameDayBucket() {
        let now = Date()
        let sameDayLater = calendar.date(byAdding: .hour, value: 3, to: now)!
        let vm = makeViewModel(entries: [entry(loggedAt: now), entry(loggedAt: sameDayLater)])

        XCTAssertEqual(vm.activityBuckets.count, 1)
        XCTAssertEqual(vm.activityBuckets.first?.count, 2)
    }

    func test_activityBucketMatching_findsBucketContainingTappedDate() {
        let now = Date()
        let vm = makeViewModel(entries: [entry(loggedAt: now)])

        let bucket = vm.activityBucket(matching: now)

        XCTAssertNotNil(bucket)
        XCTAssertEqual(bucket?.count, 1)
    }

    func test_activityBucketMatching_returnsNilForDateOutsideAnyBucket() {
        let now = Date()
        let vm = makeViewModel(entries: [entry(loggedAt: now)])

        XCTAssertNil(vm.activityBucket(matching: daysAgo(100, from: now)))
    }

    // MARK: - Discovery rate

    func test_discoveryRate_distinguishesNewArtistsFromEstablishedOnes() {
        let now = Date()
        let establishedArtistOldEntry = entry(loggedAt: daysAgo(60, from: now), track: track(id: "t1", artistId: "established"))
        let establishedArtistRecentEntry = entry(loggedAt: now, track: track(id: "t1", artistId: "established"))
        let newArtistEntry = entry(loggedAt: daysAgo(5, from: now), track: track(id: "t2", artistId: "new"))
        let vm = makeViewModel(entries: [establishedArtistOldEntry, establishedArtistRecentEntry, newArtistEntry])
        vm.timeRange = .shortTerm

        XCTAssertEqual(vm.discoveryRate, 0.5)
    }

    func test_discoveryRate_noArtistsInPeriod_returnsNil() {
        let vm = makeViewModel(entries: [])
        XCTAssertNil(vm.discoveryRate)
    }

    // MARK: - Most replayed track

    func test_mostReplayedTrack_requiresMoreThanOneLoggedEntry() {
        let now = Date()
        let repeated = track(id: "t1", name: "Repeated")
        let vm = makeViewModel(entries: [
            entry(loggedAt: now, track: repeated),
            entry(loggedAt: now, track: repeated),
            entry(loggedAt: now, track: track(id: "t2", name: "Once")),
        ])

        XCTAssertEqual(vm.mostReplayedTrack?.track.id, "t1")
        XCTAssertEqual(vm.mostReplayedTrack?.count, 2)
    }

    func test_mostReplayedTrack_allTracksLoggedOnce_returnsNil() {
        let now = Date()
        let vm = makeViewModel(entries: [
            entry(loggedAt: now, track: track(id: "t1")),
            entry(loggedAt: now, track: track(id: "t2")),
        ])

        XCTAssertNil(vm.mostReplayedTrack)
    }

    // MARK: - Top artist mismatch

    func test_topArtistMismatch_diaryTopDiffersFromSpotifyTop_returnsMismatch() {
        let now = Date()
        let spotifyTop = artist(id: "spotify-fav", name: "Spotify Favorite")
        let diaryFavoriteTrack = track(id: "t1", artistId: "diary-fav", artistName: "Diary Favorite")
        let vm = makeViewModel(
            entries: [
                entry(loggedAt: now, track: diaryFavoriteTrack),
                entry(loggedAt: now, track: diaryFavoriteTrack),
            ],
            topArtists: [spotifyTop]
        )

        let mismatch = vm.topArtistMismatch
        XCTAssertEqual(mismatch?.spotifyTop.id, "spotify-fav")
        XCTAssertEqual(mismatch?.diaryTopName, "Diary Favorite")
        XCTAssertEqual(mismatch?.diaryTopCount, 2)
    }

    func test_topArtistMismatch_diaryTopMatchesSpotifyTop_returnsNil() {
        let now = Date()
        let sameArtistTrack = track(id: "t1", artistId: "shared", artistName: "Shared")
        let vm = makeViewModel(
            entries: [entry(loggedAt: now, track: sameArtistTrack)],
            topArtists: [artist(id: "shared", name: "Shared")]
        )

        XCTAssertNil(vm.topArtistMismatch)
    }

    // MARK: - Engagement breakdown

    func test_engagementMoodBreakdown_omitsLevelsWithNoEntries() {
        let now = Date()
        let vm = makeViewModel(entries: [
            entry(loggedAt: now, engagementLevel: .quickTap),
            entry(loggedAt: now, engagementLevel: .quickTap),
        ])

        let breakdown = vm.engagementMoodBreakdown
        XCTAssertEqual(breakdown.map(\.level), [.quickTap])
        XCTAssertEqual(breakdown.first?.count, 2)
    }

    // MARK: - Activity heatmap

    func test_activityHeatmap_alwaysReturnsFullSevenByBlockGrid() {
        let vm = makeViewModel(entries: [])
        XCTAssertEqual(vm.activityHeatmap.count, 7 * (24 / StatsViewModel.heatmapHourBlockSize))
        XCTAssertEqual(vm.heatmapMaxCount, 0)
    }

    func test_activityHeatmap_bucketsEntryByWeekdayAndHourBlock() {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 3 // a Monday
        components.hour = 10
        let date = calendar.date(from: components)!
        let vm = makeViewModel(entries: [entry(loggedAt: date, playedAt: date)])

        XCTAssertEqual(vm.heatmapMaxCount, 1)
        let weekday = calendar.component(.weekday, from: date)
        let expectedBlockStart = (10 / StatsViewModel.heatmapHourBlockSize) * StatsViewModel.heatmapHourBlockSize
        let cell = vm.activityHeatmap.first { $0.weekday == weekday && $0.hourBlockStart == expectedBlockStart }
        XCTAssertEqual(cell?.count, 1)
    }

    // MARK: - Axis tick values (nice-number rounding)

    func test_moodAxisTickValues_noEntries_returnsZeroOnly() {
        let vm = makeViewModel(entries: [])
        XCTAssertEqual(vm.moodAxisTickValues, [0])
    }

    func test_moodAxisTickValues_roundsStepToNiceNumber() {
        let now = Date()
        var entries: [DiaryEntry] = []
        for _ in 0..<5 { entries.append(entry(loggedAt: now, tags: [.happy])) }
        let vm = makeViewModel(entries: entries)

        // max = 5 -> rawStep 1.25 -> nice step 2 -> [0, 2, 4]
        XCTAssertEqual(vm.moodAxisTickValues, [0, 2, 4])
    }

    // MARK: - Genre breakdown

    func test_genreCounts_afterLoadingBreakdown_countsEntriesPerGenre() async {
        let now = Date()
        let rockTrack = track(id: "t1", artistId: "rock-artist")
        let jazzTrack = track(id: "t2", artistId: "jazz-artist")
        let vm = makeViewModel(entries: [
            entry(loggedAt: now, track: rockTrack),
            entry(loggedAt: now, track: rockTrack),
            entry(loggedAt: now, track: jazzTrack),
        ])

        let spotify = FakeSpotifyRepository()
        spotify.artistsById = [
            "rock-artist": artist(id: "rock-artist", name: "Rock Artist"),
            "jazz-artist": artist(id: "jazz-artist", name: "Jazz Artist"),
        ]
        spotify.artistsById["rock-artist"] = Artist(id: "rock-artist", name: "Rock Artist", genres: ["rock"], popularity: 0, imageURL: nil)
        spotify.artistsById["jazz-artist"] = Artist(id: "jazz-artist", name: "Jazz Artist", genres: ["jazz"], popularity: 0, imageURL: nil)

        let vmWithFakes = StatsViewModel(
            diaryRepository: FakeDiaryRepository(),
            spotifyRepository: spotify,
            tasteRepository: FakeTasteRepository()
        )
        vmWithFakes.entries = vm.entries

        await vmWithFakes.loadGenreBreakdown()

        let counts = Dictionary(uniqueKeysWithValues: vmWithFakes.genreCounts.map { ($0.genre, $0.count) })
        XCTAssertEqual(counts["rock"], 2)
        XCTAssertEqual(counts["jazz"], 1)
    }

    func test_topGenreMood_afterLoadingBreakdown_picksDominantMoodForTopGenre() async {
        let now = Date()
        let rockTrack = track(id: "t1", artistId: "rock-artist")
        let vm = StatsViewModel(
            diaryRepository: FakeDiaryRepository(),
            spotifyRepository: {
                let spotify = FakeSpotifyRepository()
                spotify.artistsById = ["rock-artist": Artist(id: "rock-artist", name: "Rock Artist", genres: ["rock"], popularity: 0, imageURL: nil)]
                return spotify
            }(),
            tasteRepository: FakeTasteRepository()
        )
        vm.entries = [
            entry(loggedAt: now, track: rockTrack, tags: [.energetic]),
            entry(loggedAt: now, track: rockTrack, tags: [.energetic]),
            entry(loggedAt: now, track: rockTrack, tags: [.calm]),
        ]

        await vm.loadGenreBreakdown()

        let result = vm.topGenreMood
        XCTAssertEqual(result?.genre, "rock")
        XCTAssertEqual(result?.mood, .energetic)
    }
}
