//
//  CurrentlyPlayingState.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

struct PlaybackContext: Sendable, Equatable {
    enum ContextType: String, Sendable {
        case playlist, album, artist, collection, unknown
    }

    let type: ContextType
    let title: String?
    let uri: String
}

struct CurrentlyPlayingState: Sendable, Equatable {
    let track: Track
    let isPlaying: Bool
    var progressMs: Int
    let timestamp: Date
    let context: PlaybackContext?
}
