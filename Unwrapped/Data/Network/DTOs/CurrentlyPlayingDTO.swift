//
//  CurrentlyPlayingDTO.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

nonisolated struct CurrentlyPlayingDTO: Decodable, Sendable {
    let isPlaying: Bool
    let progressMs: Int?
    let timestamp: Int64
    let item: TrackDTO?
    let context: PlaybackContextDTO?

    enum CodingKeys: String, CodingKey {
        case item, context, timestamp
        case isPlaying = "is_playing"
        case progressMs = "progress_ms"
    }
}
