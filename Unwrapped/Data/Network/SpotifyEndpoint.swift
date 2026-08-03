//
//  SpotifyEndpoint.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

protocol SpotifyEndpoint: Sendable {
    nonisolated var path: String { get }
    nonisolated var method: String { get }
    nonisolated var queryItems: [URLQueryItem]? { get }
}

extension SpotifyEndpoint {
    var method: String { "GET" }
    var queryItems: [URLQueryItem]? { nil }
}

struct ProfileEndpoint: SpotifyEndpoint {
    var path: String { "me" }
}

struct CurrentlyPlayingEndpoint: SpotifyEndpoint {
    var path: String { "me/player/currently-playing" }
}

struct RecentlyPlayedEndpoint: SpotifyEndpoint {
    let limit: Int
    let before: Int?

    var path: String { "me/player/recently-played" }

    var queryItems: [URLQueryItem]? {
        var items = [URLQueryItem(name: "limit", value: String(limit))]
        if let before { items.append(URLQueryItem(name: "before", value: String(before))) }
        return items
    }
}

struct TopTracksEndpoint: SpotifyEndpoint {
    let timeRange: String
    let limit: Int

    var path: String { "me/top/tracks" }

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "time_range", value: timeRange),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
    }
}

struct TopArtistsEndpoint: SpotifyEndpoint {
    let timeRange: String
    let limit: Int

    var path: String { "me/top/artists" }

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "time_range", value: timeRange),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
    }
}

struct SearchTracksEndpoint: SpotifyEndpoint {
    let query: String
    let limit: Int
    let offset: Int

    var path: String { "search" }

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "track"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]
    }
}

struct TrackEndpoint: SpotifyEndpoint {
    let id: String

    var path: String { "tracks/\(id)" }
}

struct ArtistEndpoint: SpotifyEndpoint {
    let id: String

    var path: String { "artists/\(id)" }
}

struct PlayEndpoint: SpotifyEndpoint {
    var path: String { "me/player/play" }
    var method: String { "PUT" }
}

struct PauseEndpoint: SpotifyEndpoint {
    var path: String { "me/player/pause" }
    var method: String { "PUT" }
}
