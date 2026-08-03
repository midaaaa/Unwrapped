//
//  TasteRepository.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation
import SwiftData

@ModelActor
actor TasteRepository: TasteRepositoryProtocol {
    @discardableResult
    func save(_ snapshot: TasteSnapshot) async throws -> TasteSnapshot {
        let snapshotId = snapshot.id
        let descriptor = FetchDescriptor<TasteSnapshotModel>(
            predicate: #Predicate { $0.id == snapshotId }
        )

        let model: TasteSnapshotModel
        if let existing = try modelContext.fetch(descriptor).first {
            for entry in existing.trackEntries { modelContext.delete(entry) }
            for entry in existing.artistEntries { modelContext.delete(entry) }
            existing.date = snapshot.date
            model = existing
        } else {
            model = TasteSnapshotModel(id: snapshot.id, date: snapshot.date)
            modelContext.insert(model)
        }

        model.trackEntries = try snapshot.trackEntries.map { entry in
            let trackModel = try TrackArtistCacheStore.upsertTrack(entry.track, in: modelContext)
            let entryModel = TasteSnapshotTrackEntryModel(rank: entry.rank, snapshot: model, track: trackModel)
            modelContext.insert(entryModel)
            return entryModel
        }

        model.artistEntries = try snapshot.artistEntries.map { entry in
            let artistModel = try upsertArtistModel(entry.artist)
            let entryModel = TasteSnapshotArtistEntryModel(rank: entry.rank, snapshot: model, artist: artistModel)
            modelContext.insert(entryModel)
            return entryModel
        }

        try modelContext.save()

        return Self.mapToDomain(model)
    }

    func fetchSnapshots(from: Date, to: Date) async throws -> [TasteSnapshot] {
        let descriptor = FetchDescriptor<TasteSnapshotModel>(
            predicate: #Predicate { from <= $0.date && $0.date <= to },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return try modelContext.fetch(descriptor).map(Self.mapToDomain)
    }

    func fetchLatestSnapshot() async throws -> TasteSnapshot? {
        var descriptor = FetchDescriptor<TasteSnapshotModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first.map(Self.mapToDomain)
    }

    func deleteSnapshot(id: UUID) async throws {
        let descriptor = FetchDescriptor<TasteSnapshotModel>(
            predicate: #Predicate { $0.id == id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            try modelContext.save()
        }
    }

    func deleteAllSnapshots() async throws {
        let snapshots = try modelContext.fetch(FetchDescriptor<TasteSnapshotModel>())
        for snapshot in snapshots {
            modelContext.delete(snapshot)
        }
        try modelContext.save()
    }

    func clearOrphanedCache() async throws {
        let snapshotTrackIds = Set(
            try modelContext.fetch(FetchDescriptor<TasteSnapshotTrackEntryModel>())
                .compactMap { $0.track?.spotifyId }
        )

        let tracks = try modelContext.fetch(FetchDescriptor<TrackCacheModel>())
        for track in tracks where track.diaryEntries.isEmpty && !snapshotTrackIds.contains(track.spotifyId) {
            modelContext.delete(track)
        }

        let snapshotArtistIds = Set(
            try modelContext.fetch(FetchDescriptor<TasteSnapshotArtistEntryModel>())
                .compactMap { $0.artist?.spotifyId }
        )

        let artists = try modelContext.fetch(FetchDescriptor<ArtistCacheModel>())
        for artist in artists where artist.tracks.isEmpty && !snapshotArtistIds.contains(artist.spotifyId) {
            modelContext.delete(artist)
        }

        try modelContext.save()
    }

    @discardableResult
    func upsertArtist(_ artist: Artist) async throws -> Artist {
        let model = try upsertArtistModel(artist)
        try modelContext.save()
        return TrackArtistCacheStore.mapArtist(model)
    }

    func fetchCachedArtist(id: String) async throws -> Artist? {
        let descriptor = FetchDescriptor<ArtistCacheModel>(predicate: #Predicate { $0.spotifyId == id })
        return try modelContext.fetch(descriptor).first.map(TrackArtistCacheStore.mapArtist)
    }

    func fetchCachedArtistGenres(id: String) async throws -> (genres: [String], updatedAt: Date)? {
        let descriptor = FetchDescriptor<ArtistCacheModel>(predicate: #Predicate { $0.spotifyId == id })
        guard let model = try modelContext.fetch(descriptor).first else { return nil }
        return (model.genres, model.genresUpdatedAt ?? .distantPast)
    }

    private func upsertArtistModel(_ artist: Artist) throws -> ArtistCacheModel {
        let artistId = artist.id
        let descriptor = FetchDescriptor<ArtistCacheModel>(
            predicate: #Predicate { $0.spotifyId == artistId }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.name = artist.name
            existing.genres = artist.genres
            existing.genresUpdatedAt = .now
            existing.popularity = artist.popularity
            existing.imageURL = artist.imageURL
            return existing
        }

        let new = ArtistCacheModel(
            spotifyId: artist.id,
            name: artist.name,
            genres: artist.genres,
            genresUpdatedAt: .now,
            popularity: artist.popularity,
            imageURL: artist.imageURL
        )
        modelContext.insert(new)
        return new
    }

    private nonisolated static func mapToDomain(_ model: TasteSnapshotModel) -> TasteSnapshot {
        TasteSnapshot(
            id: model.id,
            date: model.date,
            trackEntries: model.trackEntries.compactMap { entry in
                guard let trackModel = entry.track else { return nil }
                return TasteSnapshotTrackEntry(rank: entry.rank, track: TrackArtistCacheStore.mapTrack(trackModel))
            },
            artistEntries: model.artistEntries.compactMap { entry in
                guard let artistModel = entry.artist else { return nil }
                return TasteSnapshotArtistEntry(rank: entry.rank, artist: TrackArtistCacheStore.mapArtist(artistModel))
            }
        )
    }
}
