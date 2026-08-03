//
//  TasteRepositoryProtocol.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation

protocol TasteRepositoryProtocol: Sendable {
    @discardableResult
    func save(_ snapshot: TasteSnapshot) async throws -> TasteSnapshot

    func fetchSnapshots(from: Date, to: Date) async throws -> [TasteSnapshot]

    func fetchLatestSnapshot() async throws -> TasteSnapshot?

    func deleteSnapshot(id: UUID) async throws

    func deleteAllSnapshots() async throws

    func clearOrphanedCache() async throws

    @discardableResult
    func upsertArtist(_ artist: Artist) async throws -> Artist

    func fetchCachedArtist(id: String) async throws -> Artist?

    func fetchCachedArtistGenres(id: String) async throws -> (genres: [String], updatedAt: Date)?
}
