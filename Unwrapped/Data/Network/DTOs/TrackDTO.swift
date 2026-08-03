//
//  TrackDTO.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

nonisolated struct TrackDTO: Decodable, Sendable {
    struct ArtistDTO: Decodable, Sendable {
        let id: String
        let name: String
    }

    struct AlbumDTO: Decodable, Sendable {
        let name: String
        let images: [SpotifyImageDTO]?
    }

    let id: String
    let name: String
    let durationMs: Int
    let explicit: Bool
    let uri: String
    let artists: [ArtistDTO]
    let album: AlbumDTO

    enum CodingKeys: String, CodingKey {
        case id, name, explicit, uri, artists, album
        case durationMs = "duration_ms"
    }
}
