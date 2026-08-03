//
//  RecentlyPlayedItem.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

struct RecentlyPlayedItem: Sendable, Equatable, Identifiable {
    var id: String { "\(track.id)-\(playedAt.timeIntervalSince1970)" }

    let track: Track
    let playedAt: Date
    let context: PlaybackContext?
}
