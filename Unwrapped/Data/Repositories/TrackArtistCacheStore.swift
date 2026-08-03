//
//  TrackArtistCacheStore.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation
import SwiftData

nonisolated enum TrackArtistCacheStore {
    @discardableResult
    static func upsertTrack(_ track: Track, in context: ModelContext) throws -> TrackCacheModel {
        let trackId = track.id
        let descriptor = FetchDescriptor<TrackCacheModel>(
            predicate: #Predicate { $0.spotifyId == trackId }
        )

        let artistModels = try zip(track.artistIds, track.artistNames).map { id, name in
            try upsertPartialArtist(id: id, name: name, in: context)
        }

        if let existing = try context.fetch(descriptor).first {
            existing.name = track.name
            existing.albumName = track.albumName
            existing.albumImageURL = track.albumImageURL
            existing.durationMs = track.durationMs
            existing.explicit = track.explicit
            existing.uri = track.uri
            if !artistModels.isEmpty {
                existing.artists = artistModels
                existing.artistOrder = track.artistIds
            }
            return existing
        }

        let new = TrackCacheModel(
            spotifyId: track.id,
            name: track.name,
            albumName: track.albumName,
            albumImageURL: track.albumImageURL,
            durationMs: track.durationMs,
            explicit: track.explicit,
            uri: track.uri,
            artists: artistModels,
            artistOrder: track.artistIds
        )
        context.insert(new)
        return new
    }

    @discardableResult
    static func upsertPartialArtist(id: String, name: String, in context: ModelContext) throws -> ArtistCacheModel {
        let descriptor = FetchDescriptor<ArtistCacheModel>(
            predicate: #Predicate { $0.spotifyId == id }
        )

        if let existing = try context.fetch(descriptor).first {
            existing.name = name
            return existing
        }

        let new = ArtistCacheModel(spotifyId: id, name: name, popularity: 0)
        context.insert(new)
        return new
    }

    static func mapTrack(_ trackModel: TrackCacheModel) -> Track {
        let orderedArtists = trackModel.artistOrder.compactMap { id in
            trackModel.artists.first { $0.spotifyId == id }
        }
        return Track(
            id: trackModel.spotifyId,
            name: trackModel.name,
            artistNames: orderedArtists.map(\.name),
            artistIds: orderedArtists.map(\.spotifyId),
            albumName: trackModel.albumName,
            albumImageURL: trackModel.albumImageURL,
            durationMs: trackModel.durationMs,
            explicit: trackModel.explicit,
            uri: trackModel.uri,
            artistImageURLs: orderedArtists.map(\.imageURL)
        )
    }

    static func mapArtist(_ artistModel: ArtistCacheModel) -> Artist {
        Artist(
            id: artistModel.spotifyId,
            name: artistModel.name,
            genres: artistModel.genres,
            popularity: artistModel.popularity,
            imageURL: artistModel.imageURL
        )
    }
}
