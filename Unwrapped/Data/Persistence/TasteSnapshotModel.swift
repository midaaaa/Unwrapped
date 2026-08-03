//
//  TasteSnapshotModel.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation
import SwiftData

@Model
final class TasteSnapshotModel {
    @Attribute(.unique)
    var id: UUID
    var date: Date
    @Relationship(deleteRule: .cascade, inverse: \TasteSnapshotTrackEntryModel.snapshot)
    var trackEntries: [TasteSnapshotTrackEntryModel] = []
    @Relationship(deleteRule: .cascade, inverse: \TasteSnapshotArtistEntryModel.snapshot)
    var artistEntries: [TasteSnapshotArtistEntryModel] = []

    init(
        id: UUID = UUID(),
        date: Date,
        trackEntries: [TasteSnapshotTrackEntryModel] = [],
        artistEntries: [TasteSnapshotArtistEntryModel] = []
    ) {
        self.id = id
        self.date = date
        self.trackEntries = trackEntries
        self.artistEntries = artistEntries
    }
}
