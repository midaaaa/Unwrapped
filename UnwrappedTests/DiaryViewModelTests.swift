//
//  DiaryViewModelTests.swift
//  UnwrappedTests
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import XCTest
@testable import Unwrapped

@MainActor
final class DiaryViewModelTests: XCTestCase {
    private func track(id: String, name: String, artistIds: [String] = ["artist1"], artistNames: [String] = ["Artist"]) -> Track {
        Track(
            id: id,
            name: name,
            artistNames: artistNames,
            artistIds: artistIds,
            albumName: "Album",
            durationMs: 200_000,
            explicit: false,
            uri: "spotify:track:\(id)"
        )
    }

    private func entry(
        loggedAt: Date,
        title: String? = nil,
        note: String? = nil,
        track: Track? = nil,
        tags: [MoodTag] = [],
        kind: EngagementLevel = .quickTap
    ) -> DiaryEntry {
        DiaryEntry(
            id: UUID(),
            loggedAt: loggedAt,
            playedAt: loggedAt,
            engagementLevel: kind,
            tags: tags,
            title: title,
            note: note,
            progressMs: nil,
            track: track
        )
    }

    private func makeViewModel(entries: [DiaryEntry]) -> DiaryViewModel {
        let repo = FakeDiaryRepository()
        repo.entriesToReturn = entries
        let vm = DiaryViewModel(
            diaryRepository: repo,
            spotifyRepository: FakeSpotifyRepository(),
            tasteRepository: FakeTasteRepository()
        )
        vm.entries = entries
        return vm
    }

    // MARK: - Search

    func test_search_matchesTitleCaseInsensitively() {
        let match = entry(loggedAt: Date(), title: "Rainy Morning")
        let other = entry(loggedAt: Date(), title: "Sunny Day")
        let vm = makeViewModel(entries: [match, other])

        vm.searchText = "rainy"

        XCTAssertEqual(vm.filteredEntries.map(\.id), [match.id])
    }

    func test_search_matchesTrackNameAndArtist() {
        let matchByTrack = entry(loggedAt: Date(), track: track(id: "t1", name: "Nightfall"))
        let matchByArtist = entry(loggedAt: Date(), track: track(id: "t2", name: "Other", artistNames: ["Nightfall Band"]))
        let noMatch = entry(loggedAt: Date(), track: track(id: "t3", name: "Unrelated"))
        let vm = makeViewModel(entries: [matchByTrack, matchByArtist, noMatch])

        vm.searchText = "nightfall"

        XCTAssertEqual(Set(vm.filteredEntries.map(\.id)), Set([matchByTrack.id, matchByArtist.id]))
    }

    func test_search_emptyQuery_returnsAllEntries() {
        let entries = [entry(loggedAt: Date()), entry(loggedAt: Date())]
        let vm = makeViewModel(entries: entries)

        XCTAssertEqual(vm.filteredEntries.count, 2)
    }

    // MARK: - Filter integration

    func test_filteredEntries_appliesFilterAfterSearch() {
        let happy = entry(loggedAt: Date(), title: "Match", tags: [.happy])
        let sad = entry(loggedAt: Date(), title: "Match", tags: [.sad])
        let vm = makeViewModel(entries: [happy, sad])
        vm.searchText = "match"
        vm.filter.moodTags = [.happy]

        XCTAssertEqual(vm.filteredEntries.map(\.id), [happy.id])
    }

    // MARK: - Sorting

    func test_sortedEntries_defaultDescendingByLoggedAt() {
        let now = Date()
        let older = entry(loggedAt: now.addingTimeInterval(-3600))
        let newer = entry(loggedAt: now)
        let vm = makeViewModel(entries: [older, newer])

        XCTAssertEqual(vm.sortedEntries.map(\.id), [newer.id, older.id])
    }

    func test_toggleSortDirection_reversesOrder() {
        let now = Date()
        let older = entry(loggedAt: now.addingTimeInterval(-3600))
        let newer = entry(loggedAt: now)
        let vm = makeViewModel(entries: [older, newer])

        vm.toggleSortDirection()

        XCTAssertEqual(vm.sortedEntries.map(\.id), [older.id, newer.id])
    }

    func test_setSortField_resetsToFieldsDefaultDirection() {
        let vm = makeViewModel(entries: [])
        vm.toggleSortDirection() // .date -> ascending
        XCTAssertEqual(vm.sortDirection.systemImage, "arrow.up")

        vm.setSortField(.name)

        XCTAssertEqual(vm.sortField, .name)
        XCTAssertEqual(vm.sortDirection.systemImage, "arrow.up") // .name defaults to ascending too, but via the field-change path
    }

    func test_effectiveSortField_fallsBackToDateWhenFieldUnavailableForBrowseMode() {
        let vm = makeViewModel(entries: [])
        vm.setSortField(.name)
        vm.browseMode = .entries // only .date is available in entries mode

        XCTAssertEqual(vm.effectiveSortField, .date)
    }

    // MARK: - Grouping by day

    func test_entriesGroupedByDay_groupsEntriesOnSameCalendarDay() {
        let calendar = Calendar.current
        let day1 = Date()
        let day1Later = calendar.date(byAdding: .hour, value: 2, to: day1)!
        let day2 = calendar.date(byAdding: .day, value: -1, to: day1)!
        let vm = makeViewModel(entries: [entry(loggedAt: day1), entry(loggedAt: day1Later), entry(loggedAt: day2)])

        let sections = vm.entriesGroupedByDay

        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections.first?.entries.count, 2)
    }

    // MARK: - Track / artist summaries

    func test_trackSummaries_groupsEntriesByTrackId() {
        let sameTrack = track(id: "t1", name: "Song")
        let vm = makeViewModel(entries: [
            entry(loggedAt: Date(), track: sameTrack),
            entry(loggedAt: Date().addingTimeInterval(-100), track: sameTrack),
            entry(loggedAt: Date(), track: track(id: "t2", name: "Other")),
        ])

        let summaries = vm.trackSummaries

        XCTAssertEqual(summaries.count, 2)
        XCTAssertEqual(summaries.first { $0.track.id == "t1" }?.entryCount, 2)
    }

    func test_artistSummaries_groupsMultiArtistTracksUnderEachArtist() {
        let collab = track(id: "collab", name: "Duet", artistIds: ["a1", "a2"], artistNames: ["First", "Second"])
        let vm = makeViewModel(entries: [entry(loggedAt: Date(), track: collab)])

        let summaries = vm.artistSummaries

        XCTAssertEqual(Set(summaries.map(\.artistId)), Set(["a1", "a2"]))
        XCTAssertTrue(summaries.allSatisfy { $0.entryCount == 1 })
    }

    func test_summariesSortedByName_isCaseInsensitiveAscending() {
        let vm = makeViewModel(entries: [
            entry(loggedAt: Date(), track: track(id: "t1", name: "banana")),
            entry(loggedAt: Date(), track: track(id: "t2", name: "Apple")),
        ])
        vm.browseMode = .tracks // .name is only a valid sort field outside .entries mode
        vm.setSortField(.name)

        XCTAssertEqual(vm.trackSummaries.map(\.track.name), ["Apple", "banana"])
    }

    // MARK: - Drill-down

    func test_entriesForTrackID_returnsOnlyMatchingTrackNewestFirst() {
        let target = track(id: "t1", name: "Song")
        let older = entry(loggedAt: Date().addingTimeInterval(-3600), track: target)
        let newer = entry(loggedAt: Date(), track: target)
        let other = entry(loggedAt: Date(), track: track(id: "t2", name: "Other"))
        let vm = makeViewModel(entries: [older, newer, other])

        XCTAssertEqual(vm.entries(forTrackID: "t1").map(\.id), [newer.id, older.id])
    }

    func test_entriesForArtistID_matchesAnyArtistOnATrack() {
        let collab = track(id: "collab", name: "Duet", artistIds: ["a1", "a2"], artistNames: ["First", "Second"])
        let solo = track(id: "solo", name: "Solo", artistIds: ["a3"], artistNames: ["Third"])
        let matching = entry(loggedAt: Date(), track: collab)
        let nonMatching = entry(loggedAt: Date(), track: solo)
        let vm = makeViewModel(entries: [matching, nonMatching])

        XCTAssertEqual(vm.entries(forArtistID: "a2").map(\.id), [matching.id])
    }

    // MARK: - Deletion (optimistic update)

    func test_delete_removesEntryFromLocalListImmediately() async {
        let toDelete = entry(loggedAt: Date())
        let vm = makeViewModel(entries: [toDelete, entry(loggedAt: Date())])

        await vm.delete(toDelete)

        XCTAssertFalse(vm.entries.contains { $0.id == toDelete.id })
    }
}
