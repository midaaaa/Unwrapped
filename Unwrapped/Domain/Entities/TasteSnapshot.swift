//
//  TasteSnapshot.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation

struct TasteSnapshot: Sendable, Equatable, Identifiable {
    let id: UUID
    let date: Date
    let trackEntries: [TasteSnapshotTrackEntry]
    let artistEntries: [TasteSnapshotArtistEntry]
}

struct TasteSnapshotTrackEntry: Sendable, Equatable {
    let rank: Int
    let track: Track
}

struct TasteSnapshotArtistEntry: Sendable, Equatable {
    let rank: Int
    let artist: Artist
}
