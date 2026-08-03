//
//  TasteSnapshotTrackEntryModel.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation
import SwiftData

@Model
final class TasteSnapshotTrackEntryModel {
    var rank: Int
    var snapshot: TasteSnapshotModel?
    var track: TrackCacheModel?

    init(rank: Int, snapshot: TasteSnapshotModel? = nil, track: TrackCacheModel? = nil) {
        self.rank = rank
        self.snapshot = snapshot
        self.track = track
    }
}
