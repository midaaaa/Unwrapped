//
//  DiaryRepositoryProtocol.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation

protocol DiaryRepositoryProtocol: Sendable {
    @discardableResult
    func save(_ entry: DiaryEntry) async throws -> DiaryEntry

    func fetchEntries(from: Date, to: Date) async throws -> [DiaryEntry]

    func fetchEntries(forTrackID trackID: String) async throws -> [DiaryEntry]

    func fetchAllEntries() async throws -> [DiaryEntry]

    func deleteEntry(id: UUID) async throws

    func deleteAllEntries() async throws
}
