//
//  SpotifyRepository.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

final class SpotifyRepository: SpotifyRepositoryProtocol {
    private let apiClient: SpotifyAPIClient

    init(apiClient: SpotifyAPIClient) {
        self.apiClient = apiClient
    }

    func fetchCurrentlyPlaying() async throws -> PlaybackResponse<CurrentlyPlayingState> {
        do {
            let dto = try await apiClient.decode(CurrentlyPlayingEndpoint(), as: CurrentlyPlayingDTO.self)
            guard let state = SpotifyDTOMapper.map(dto) else {
                return .noActivePlayback
            }
            return .active(state)
        } catch APIError.noActivePlayback {
            return .noActivePlayback
        }
    }

    func fetchRecentlyPlayed(limit: Int, before: Date?) async throws -> [RecentlyPlayedItem] {
        let beforeMs = before.map { Int($0.timeIntervalSince1970 * 1_000) }
        let dto = try await apiClient.decode(
            RecentlyPlayedEndpoint(limit: limit, before: beforeMs),
            as: RecentlyPlayedResponseDTO.self
        )
        return dto.items.compactMap(SpotifyDTOMapper.map)
    }

    func fetchTopTracks(timeRange: TopItemsTimeRange, limit: Int) async throws -> [Track] {
        let dto = try await apiClient.decode(
            TopTracksEndpoint(timeRange: timeRange.rawValue, limit: limit),
            as: ItemsResponseDTO<TrackDTO>.self
        )
        return dto.items.map(SpotifyDTOMapper.map)
    }

    func fetchTopArtists(timeRange: TopItemsTimeRange, limit: Int) async throws -> [Artist] {
        let dto = try await apiClient.decode(
            TopArtistsEndpoint(timeRange: timeRange.rawValue, limit: limit),
            as: ItemsResponseDTO<TopArtistDTO>.self
        )
        return dto.items.map(SpotifyDTOMapper.map)
    }

    func fetchArtist(id: String) async throws -> Artist {
        let dto = try await apiClient.decode(ArtistEndpoint(id: id), as: TopArtistDTO.self)
        return SpotifyDTOMapper.map(dto)
    }

    func searchTracks(query: String, limit: Int, offset: Int) async throws -> [Track] {
        let dto = try await apiClient.decode(
            SearchTracksEndpoint(query: query, limit: limit, offset: offset),
            as: SearchTracksResponseDTO.self
        )
        return dto.tracks.items.map(SpotifyDTOMapper.map)
    }

    func fetchProfile() async throws -> UserProfile {
        let dto = try await apiClient.decode(ProfileEndpoint(), as: UserProfileDTO.self)
        return SpotifyDTOMapper.map(dto)
    }

    func play() async throws {
        try await apiClient.perform(PlayEndpoint())
    }

    func pause() async throws {
        try await apiClient.perform(PauseEndpoint())
    }
}
