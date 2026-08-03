//
//  TrackCacheModel.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation
import SwiftData

@Model
final class TrackCacheModel {
    @Attribute(.unique)
    var spotifyId: String
    var name: String
    var albumName: String
    var albumImageURL: URL?
    var durationMs: Int
    var explicit: Bool
    var uri: String

    @Relationship(inverse: \DiaryEntryModel.track)
    var diaryEntries: [DiaryEntryModel] = []

    var artists: [ArtistCacheModel] = []
    var artistOrder: [String] = []

    init(
        spotifyId: String,
        name: String,
        albumName: String,
        albumImageURL: URL? = nil,
        durationMs: Int,
        explicit: Bool,
        uri: String,
        artists: [ArtistCacheModel] = [],
        artistOrder: [String] = []
    ) {
        self.spotifyId = spotifyId
        self.name = name
        self.albumName = albumName
        self.albumImageURL = albumImageURL
        self.durationMs = durationMs
        self.explicit = explicit
        self.uri = uri
        self.artists = artists
        self.artistOrder = artistOrder
    }
}
