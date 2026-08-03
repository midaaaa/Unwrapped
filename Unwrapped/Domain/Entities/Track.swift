//
//  Track.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

struct Track: Sendable, Equatable, Identifiable {
    let id: String
    let name: String
    let artistNames: [String]
    let artistIds: [String]
    let albumName: String
    let albumImageURL: URL?
    let durationMs: Int
    let explicit: Bool
    let uri: String
    let artistImageURLs: [URL?]

    nonisolated init(
        id: String,
        name: String,
        artistNames: [String],
        artistIds: [String] = [],
        albumName: String,
        albumImageURL: URL? = nil,
        durationMs: Int,
        explicit: Bool,
        uri: String,
        artistImageURLs: [URL?] = []
    ) {
        self.id = id
        self.name = name
        self.artistNames = artistNames
        self.artistIds = artistIds
        self.albumName = albumName
        self.albumImageURL = albumImageURL
        self.durationMs = durationMs
        self.explicit = explicit
        self.uri = uri
        self.artistImageURLs = artistImageURLs
    }

    nonisolated var primaryArtistName: String {
        artistNames.first ?? String(localized: "Unknown Artist")
    }

    nonisolated var primaryArtistId: String? {
        artistIds.first
    }

    nonisolated var artistDisplaySummary: String {
        guard artistNames.count > 1 else { return primaryArtistName }
        return "\(primaryArtistName) +\(artistNames.count - 1)"
    }

    nonisolated var artistGroupingKeys: [(id: String, name: String)] {
        guard !artistIds.isEmpty else {
            return artistNames.isEmpty ? [] : [(primaryArtistName, primaryArtistName)]
        }
        return Array(zip(artistIds, artistNames))
    }

    nonisolated func imageURL(forArtistId artistId: String) -> URL? {
        guard let index = artistIds.firstIndex(of: artistId), index < artistImageURLs.count else { return nil }
        return artistImageURLs[index]
    }
}
