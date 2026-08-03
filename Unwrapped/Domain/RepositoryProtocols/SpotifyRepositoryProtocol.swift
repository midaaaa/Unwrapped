//
//  SpotifyRepositoryProtocol.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

enum PlaybackResponse<T: Sendable>: Sendable {
    case active(T)
    case noActivePlayback
}

enum TopItemsTimeRange: String, Sendable, CaseIterable {
    case shortTerm = "short_term"
    case mediumTerm = "medium_term"
    case longTerm = "long_term"
}

protocol SpotifyRepositoryProtocol: Sendable {
    func fetchCurrentlyPlaying() async throws -> PlaybackResponse<CurrentlyPlayingState>

    func fetchRecentlyPlayed(limit: Int, before: Date?) async throws -> [RecentlyPlayedItem]

    func fetchTopTracks(timeRange: TopItemsTimeRange, limit: Int) async throws -> [Track]

    func fetchTopArtists(timeRange: TopItemsTimeRange, limit: Int) async throws -> [Artist]

    func fetchArtist(id: String) async throws -> Artist

    func searchTracks(query: String, limit: Int, offset: Int) async throws -> [Track]

    func fetchProfile() async throws -> UserProfile

    func play() async throws

    func pause() async throws
}
