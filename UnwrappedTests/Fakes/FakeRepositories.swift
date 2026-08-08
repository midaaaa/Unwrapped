//
//  FakeRepositories.swift
//  UnwrappedTests
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import Foundation
@testable import Unwrapped

final class FakeDiaryRepository: DiaryRepositoryProtocol, @unchecked Sendable {
    var entriesToReturn: [DiaryEntry] = []
    var deletedIds: [UUID] = []

    func save(_ entry: DiaryEntry) async throws -> DiaryEntry { entry }

    func fetchEntries(from: Date, to: Date) async throws -> [DiaryEntry] {
        entriesToReturn.filter { $0.loggedAt >= from && $0.loggedAt <= to }
    }

    func fetchEntries(forTrackID trackID: String) async throws -> [DiaryEntry] {
        entriesToReturn.filter { $0.track?.id == trackID }
    }

    func fetchAllEntries() async throws -> [DiaryEntry] { entriesToReturn }

    func deleteEntry(id: UUID) async throws { deletedIds.append(id) }

    func deleteAllEntries() async throws { entriesToReturn = [] }
}

final class FakeSpotifyRepository: SpotifyRepositoryProtocol, @unchecked Sendable {
    var topTracksToReturn: [Track] = []
    var topArtistsToReturn: [Artist] = []
    var artistsById: [String: Artist] = [:]

    func fetchCurrentlyPlaying() async throws -> PlaybackResponse<CurrentlyPlayingState> { .noActivePlayback }
    func fetchRecentlyPlayed(limit: Int, before: Date?) async throws -> [RecentlyPlayedItem] { [] }
    func fetchTopTracks(timeRange: TopItemsTimeRange, limit: Int) async throws -> [Track] { topTracksToReturn }
    func fetchTopArtists(timeRange: TopItemsTimeRange, limit: Int) async throws -> [Artist] { topArtistsToReturn }
    func fetchArtist(id: String) async throws -> Artist {
        artistsById[id] ?? Artist(id: id, name: "Artist", popularity: 0, imageURL: nil)
    }
    func searchTracks(query: String, limit: Int, offset: Int) async throws -> [Track] { [] }
    func fetchProfile() async throws -> UserProfile { UserProfile(id: "u", displayName: "User", country: nil, product: .unknown, imageURL: nil) }
    func play() async throws {}
    func pause() async throws {}
}

final class FakeTasteRepository: TasteRepositoryProtocol, @unchecked Sendable {
    var savedSnapshots: [TasteSnapshot] = []

    func save(_ snapshot: TasteSnapshot) async throws -> TasteSnapshot {
        savedSnapshots.append(snapshot)
        return snapshot
    }
    func fetchSnapshots(from: Date, to: Date) async throws -> [TasteSnapshot] { [] }
    func fetchLatestSnapshot() async throws -> TasteSnapshot? { nil }
    func deleteSnapshot(id: UUID) async throws {}
    func deleteAllSnapshots() async throws {}
    func clearOrphanedCache() async throws {}
    func upsertArtist(_ artist: Artist) async throws -> Artist { artist }
    func fetchCachedArtist(id: String) async throws -> Artist? { nil }
}
