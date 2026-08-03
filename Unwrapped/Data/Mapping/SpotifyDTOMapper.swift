//
//  SpotifyDTOMapper.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

nonisolated enum SpotifyDTOMapper {
    static func map(_ dto: TrackDTO) -> Track {
        Track(
            id: dto.id,
            name: dto.name,
            artistNames: Mapping.artistNames(dto.artists),
            artistIds: Mapping.artistIds(dto.artists),
            albumName: dto.album.name,
            albumImageURL: Mapping.imageURL(dto.album.images?.first?.url),
            durationMs: dto.durationMs,
            explicit: dto.explicit,
            uri: dto.uri
        )
    }

    static func map(_ dto: TopArtistDTO) -> Artist {
        Artist(
            id: dto.id,
            name: dto.name,
            genres: dto.genres ?? [],
            popularity: dto.popularity ?? 0,
            imageURL: Mapping.imageURL(dto.images?.first?.url)
        )
    }

    static func map(_ dto: UserProfileDTO) -> UserProfile {
        UserProfile(
            id: dto.id,
            displayName: dto.displayName ?? "Unknown",
            country: dto.country,
            product: Mapping.subscriptionProduct(dto.product),
            imageURL: Mapping.imageURL(dto.images?.first?.url)
        )
    }

    static func map(_ dto: CurrentlyPlayingDTO) -> CurrentlyPlayingState? {
        guard let item = dto.item else { return nil }
        return CurrentlyPlayingState(
            track: map(item),
            isPlaying: dto.isPlaying,
            progressMs: dto.progressMs ?? 0,
            timestamp: Mapping.spotifyTimestamp(ms: dto.timestamp),
            context: Mapping.playbackContext(from: dto.context)
        )
    }

    static func map(_ dto: RecentlyPlayedResponseDTO.ItemDTO) -> RecentlyPlayedItem? {
        guard let playedAt = Mapping.iso8601Date(dto.playedAt) else { return nil }
        return RecentlyPlayedItem(
            track: map(dto.track),
            playedAt: playedAt,
            context: Mapping.playbackContext(from: dto.context)
        )
    }

    private enum Mapping {
        static func imageURL(_ string: String?) -> URL? {
            guard let string else { return nil }
            return URL(string: string)
        }

        static func artistNames(_ artists: [TrackDTO.ArtistDTO]) -> [String] {
            artists.map(\.name)
        }

        static func artistIds(_ artists: [TrackDTO.ArtistDTO]) -> [String] {
            artists.map(\.id)
        }

        static func subscriptionProduct(_ raw: String?) -> SubscriptionProduct {
            SubscriptionProduct(rawValue: raw ?? "") ?? .unknown
        }

        static func spotifyTimestamp(ms: Int64) -> Date {
            Date(timeIntervalSince1970: Double(ms) / 1_000)
        }

        private static let iso8601WithFraction: Date.ISO8601FormatStyle =
            .iso8601
            .time(includingFractionalSeconds: true)

        private static let iso8601Plain: Date.ISO8601FormatStyle = .iso8601

        static func iso8601Date(_ string: String) -> Date? {
            (try? Date(string, strategy: iso8601WithFraction))
                ?? (try? Date(string, strategy: iso8601Plain))
        }

        static func playbackContext(from dto: PlaybackContextDTO?) -> PlaybackContext? {
            guard let dto else { return nil }
            let type = PlaybackContext.ContextType(rawValue: dto.type) ?? .unknown
            return PlaybackContext(type: type, title: nil, uri: dto.uri)
        }
    }
}
