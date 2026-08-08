//
//  ArtistCacheModel.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation
import SwiftData

@Model
final class ArtistCacheModel {
    @Attribute(.unique)
    var spotifyId: String
    var name: String
    var popularity: Int
    var imageURL: URL?

    @Relationship(inverse: \TrackCacheModel.artists)
    var tracks: [TrackCacheModel] = []

    init(spotifyId: String, name: String, popularity: Int, imageURL: URL? = nil) {
        self.spotifyId = spotifyId
        self.name = name
        self.popularity = popularity
        self.imageURL = imageURL
    }
}
