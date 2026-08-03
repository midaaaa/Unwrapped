//
//  AppContainer.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import BackgroundTasks
import Foundation
import SwiftData

@MainActor
final class AppContainer {
    lazy var modelContainer: ModelContainer = {
        let schema = Schema([
            DiaryEntryModel.self,
            TrackCacheModel.self,
            ArtistCacheModel.self,
            TasteSnapshotModel.self,
            TasteSnapshotTrackEntryModel.self,
            TasteSnapshotArtistEntryModel.self
        ])
        let configuration = ModelConfiguration(schema: schema)

        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    lazy var diaryRepository: DiaryRepositoryProtocol = DiaryRepository(modelContainer: modelContainer)

    lazy var tasteRepository: TasteRepositoryProtocol = TasteRepository(modelContainer: modelContainer)

    lazy var keychainStore: KeychainTokenStoreProtocol = KeychainTokenStore()

    lazy var authService: SpotifyAuthService = {
        SpotifyAuthService(
            clientID: SpotifyConfig.clientID,
            redirectURI: SpotifyConfig.redirectURI,
            scopes: SpotifyConfig.scopes,
            keychain: keychainStore
        )
    }()

    lazy var apiClient: SpotifyAPIClient = {
        SpotifyAPIClient(tokenProvider: authService)
    }()

    lazy var spotifyRepository: SpotifyRepositoryProtocol = {
        SpotifyRepository(apiClient: apiClient)
    }()

    // many views have this player
    lazy var playerViewModel: PlayerViewModel = PlayerViewModel(
        repository: spotifyRepository,
        diaryRepository: diaryRepository
    )

    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            repository: spotifyRepository,
            diaryRepository: diaryRepository,
            tasteRepository: tasteRepository
        )
    }

    func makeDiaryViewModel() -> DiaryViewModel {
        DiaryViewModel(diaryRepository: diaryRepository, spotifyRepository: spotifyRepository, tasteRepository: tasteRepository)
    }

    func makeStatsViewModel() -> StatsViewModel {
        StatsViewModel(diaryRepository: diaryRepository, spotifyRepository: spotifyRepository, tasteRepository: tasteRepository)
    }

    func makeLogViewModel() -> LogViewModel {
        LogViewModel(repository: spotifyRepository, diaryRepository: diaryRepository)
    }

    // MARK: - Background refresh

    func scheduleTasteSnapshotRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: BackgroundTaskConfig.tasteSnapshotRefreshID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: BackgroundTaskConfig.refreshInterval)
        try? BGTaskScheduler.shared.submit(request)
    }

    func performTasteSnapshotRefresh() async {
        guard await authService.isAuthenticated else { return }
        try? await TasteSnapshotRefresher.fetchAndSave(spotifyRepository: spotifyRepository, tasteRepository: tasteRepository)
    }
}
