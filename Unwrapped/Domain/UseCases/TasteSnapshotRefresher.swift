//
//  TasteSnapshotRefresher.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import Foundation

enum TasteSnapshotRefresher {
    @discardableResult
    static func save(tracks: [Track], artists: [Artist], into tasteRepository: TasteRepositoryProtocol) async throws -> TasteSnapshot {
        let snapshot = TasteSnapshot(
            id: UUID(),
            date: .now,
            trackEntries: tracks.enumerated().map { TasteSnapshotTrackEntry(rank: $0.offset + 1, track: $0.element) },
            artistEntries: artists.enumerated().map { TasteSnapshotArtistEntry(rank: $0.offset + 1, artist: $0.element) }
        )
        return try await tasteRepository.save(snapshot)
    }

    static func fetchAndSave(
        spotifyRepository: SpotifyRepositoryProtocol,
        tasteRepository: TasteRepositoryProtocol,
        timeRange: TopItemsTimeRange = .shortTerm,
        limit: Int = 10
    ) async throws {
        async let tracks = spotifyRepository.fetchTopTracks(timeRange: timeRange, limit: limit)
        async let artists = spotifyRepository.fetchTopArtists(timeRange: timeRange, limit: limit)
        let (fetchedTracks, fetchedArtists) = try await (tracks, artists)
        try await save(tracks: fetchedTracks, artists: fetchedArtists, into: tasteRepository)
    }
}
