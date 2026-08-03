//
//  DiaryRepository.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation
import SwiftData

@ModelActor
actor DiaryRepository: DiaryRepositoryProtocol {
    @discardableResult
    func save(_ entry: DiaryEntry) async throws -> DiaryEntry {
        let entryId = entry.id
        let descriptor = FetchDescriptor<DiaryEntryModel>(
            predicate: #Predicate { $0.id == entryId }
        )

        let model: DiaryEntryModel
        if let existing = try modelContext.fetch(descriptor).first {
            model = existing
        } else {
            model = DiaryEntryModel(
                id: entry.id,
                loggedAt: entry.loggedAt,
                playedAt: entry.playedAt,
                engagementLevel: entry.engagementLevel
            )
            modelContext.insert(model)
        }

        model.loggedAt = entry.loggedAt
        model.playedAt = entry.playedAt
        model.engagementLevel = entry.engagementLevel
        model.tags = entry.tags
        model.title = entry.title
        model.note = entry.note
        model.progressMs = entry.progressMs
        model.track = try entry.track.map { try TrackArtistCacheStore.upsertTrack($0, in: modelContext) }

        try modelContext.save()

        return Self.mapToDomain(model)
    }

    func fetchEntries(from: Date, to: Date) async throws -> [DiaryEntry] {
        let descriptor = FetchDescriptor<DiaryEntryModel>(
            predicate: #Predicate { $0.loggedAt >= from && $0.loggedAt < to },
            sortBy: [SortDescriptor(\.loggedAt)]
        )

        return try modelContext.fetch(descriptor).map(Self.mapToDomain)
    }

    func fetchEntries(forTrackID trackID: String) async throws -> [DiaryEntry] {
        let descriptor = FetchDescriptor<DiaryEntryModel>(
            predicate: #Predicate { $0.track?.spotifyId == trackID },
            sortBy: [SortDescriptor(\.progressMs)]
        )
        return try modelContext.fetch(descriptor).map(Self.mapToDomain)
    }

    func fetchAllEntries() async throws -> [DiaryEntry] {
        let descriptor = FetchDescriptor<DiaryEntryModel>(
            sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
        )

        return try modelContext.fetch(descriptor).map(Self.mapToDomain)
    }

    func deleteEntry(id: UUID) async throws {
        let descriptor = FetchDescriptor<DiaryEntryModel>(
            predicate: #Predicate { $0.id == id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            try modelContext.save()
        }
    }

    func deleteAllEntries() async throws {
        let entries = try modelContext.fetch(FetchDescriptor<DiaryEntryModel>())
        for entry in entries {
            modelContext.delete(entry)
        }
        try modelContext.save()
    }

    private nonisolated static func mapToDomain(_ model: DiaryEntryModel) -> DiaryEntry {
        DiaryEntry(
            id: model.id,
            loggedAt: model.loggedAt,
            playedAt: model.playedAt,
            engagementLevel: model.engagementLevel,
            tags: model.tags,
            title: model.title,
            note: model.note,
            progressMs: model.progressMs,
            track: model.track.map(TrackArtistCacheStore.mapTrack)
        )
    }
}
