//
//  TasteSnapshotArtistEntryModel.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation
import SwiftData

@Model
final class TasteSnapshotArtistEntryModel {
    var rank: Int
    var snapshot: TasteSnapshotModel?
    var artist: ArtistCacheModel?

    init(rank: Int, snapshot: TasteSnapshotModel? = nil, artist: ArtistCacheModel? = nil) {
        self.rank = rank
        self.snapshot = snapshot
        self.artist = artist
    }
}
