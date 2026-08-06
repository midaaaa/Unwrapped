//
//  LogViewModel.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 24.07.2026.
//

import Foundation

@MainActor
@Observable
final class LogViewModel {
    var recentlyPlayed: [RecentlyPlayedItem] = []
    var isLoading = false
    var errorMessage: String?
    var isUnauthenticated = false

    private let repository: SpotifyRepositoryProtocol
    private let diaryRepository: DiaryRepositoryProtocol

    init(repository: SpotifyRepositoryProtocol, diaryRepository: DiaryRepositoryProtocol) {
        self.repository = repository
        self.diaryRepository = diaryRepository
    }

    func makeEntryEditorViewModel(for item: RecentlyPlayedItem) -> EntryEditorViewModel {
        EntryEditorViewModel(
            track: item.track,
            mode: .create(initialProgressMs: 0, kind: .quickTap, playedAt: item.playedAt),
            diaryRepository: diaryRepository
        )
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        isUnauthenticated = false
        defer { isLoading = false }

        do {
            recentlyPlayed = try await repository.fetchRecentlyPlayed(limit: 50, before: nil)
        } catch AuthError.notAuthenticated {
            isUnauthenticated = true
        } catch APIError.unauthorized {
            isUnauthenticated = true
        } catch {
            if !error.isCancellation {
                errorMessage = error.localizedDescription
            }
        }
    }
}
