//
//  RecentlyPlayedDTO.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

nonisolated struct RecentlyPlayedResponseDTO: Decodable, Sendable {
    struct ItemDTO: Decodable, Sendable {
        let track: TrackDTO
        let playedAt: String
        let context: PlaybackContextDTO?

        enum CodingKeys: String, CodingKey {
            case track, context
            case playedAt = "played_at"
        }
    }

    let items: [ItemDTO]
}
