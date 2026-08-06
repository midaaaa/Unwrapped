//
//  ProfileViewModel.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation

@MainActor
@Observable
final class ProfileViewModel {
    var profile: UserProfile?
    var errorMessage: String?
    var storageErrorMessage: String?

    private let repository: SpotifyRepositoryProtocol
    private let diaryRepository: DiaryRepositoryProtocol
    private let tasteRepository: TasteRepositoryProtocol

    init(
        repository: SpotifyRepositoryProtocol,
        diaryRepository: DiaryRepositoryProtocol,
        tasteRepository: TasteRepositoryProtocol
    ) {
        self.repository = repository
        self.diaryRepository = diaryRepository
        self.tasteRepository = tasteRepository
    }

    func load() async {
        errorMessage = nil

        do {
            profile = try await repository.fetchProfile()
        } catch {
            if !error.isCancellation {
                errorMessage = error.localizedDescription
            }
        }
    }

    func clearCache() async {
        storageErrorMessage = nil
        do {
            try await tasteRepository.clearOrphanedCache()
            ImageMemoryCache.shared.clear()
        } catch {
            if !error.isCancellation {
                storageErrorMessage = error.localizedDescription
            }
        }
    }

    func deleteAllData() async {
        storageErrorMessage = nil
        do {
            try await diaryRepository.deleteAllEntries()
            try await tasteRepository.deleteAllSnapshots()
            try await tasteRepository.clearOrphanedCache()
            ImageMemoryCache.shared.clear()
        } catch {
            if !error.isCancellation {
                storageErrorMessage = error.localizedDescription
            }
        }
    }
}
