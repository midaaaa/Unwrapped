//
//  TasteSnapshotRefresherTests.swift
//  UnwrappedTests
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import XCTest
@testable import Unwrapped

@MainActor
final class TasteSnapshotRefresherTests: XCTestCase {
    private func track(id: String, name: String) -> Track {
        Track(id: id, name: name, artistNames: ["Artist"], albumName: "Album", durationMs: 200_000, explicit: false, uri: "spotify:track:\(id)")
    }

    private func artist(id: String, name: String) -> Artist {
        Artist(id: id, name: name, genres: [], popularity: 0, imageURL: nil)
    }

    func test_save_assignsOneBasedRanksInInputOrder() async throws {
        let repo = FakeTasteRepository()
        let tracks = [track(id: "t1", name: "First"), track(id: "t2", name: "Second"), track(id: "t3", name: "Third")]
        let artists = [artist(id: "a1", name: "Solo")]

        let snapshot = try await TasteSnapshotRefresher.save(tracks: tracks, artists: artists, into: repo)

        XCTAssertEqual(snapshot.trackEntries.map(\.rank), [1, 2, 3])
        XCTAssertEqual(snapshot.trackEntries.map(\.track.id), ["t1", "t2", "t3"])
        XCTAssertEqual(snapshot.artistEntries.map(\.rank), [1])
    }

    func test_save_emptyInputs_producesEmptySnapshot() async throws {
        let repo = FakeTasteRepository()
        let snapshot = try await TasteSnapshotRefresher.save(tracks: [], artists: [], into: repo)

        XCTAssertTrue(snapshot.trackEntries.isEmpty)
        XCTAssertTrue(snapshot.artistEntries.isEmpty)
    }

    func test_save_persistsSnapshotThroughRepository() async throws {
        let repo = FakeTasteRepository()
        let returned = try await TasteSnapshotRefresher.save(tracks: [track(id: "t1", name: "Song")], artists: [], into: repo)

        XCTAssertEqual(repo.savedSnapshots.count, 1)
        XCTAssertEqual(repo.savedSnapshots.first?.id, returned.id)
    }

    func test_fetchAndSave_ranksTopTracksAndArtistsFromSpotifyResponse() async throws {
        let spotify = FakeSpotifyRepository()
        spotify.topTracksToReturn = [track(id: "t1", name: "First"), track(id: "t2", name: "Second")]
        spotify.topArtistsToReturn = [artist(id: "a1", name: "Only")]
        let taste = FakeTasteRepository()

        try await TasteSnapshotRefresher.fetchAndSave(spotifyRepository: spotify, tasteRepository: taste)

        let saved = try XCTUnwrap(taste.savedSnapshots.first)
        XCTAssertEqual(saved.trackEntries.map(\.rank), [1, 2])
        XCTAssertEqual(saved.artistEntries.map(\.rank), [1])
    }
}
