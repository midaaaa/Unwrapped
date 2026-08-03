//
//  RootView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import SwiftUI

struct RootView: View {
    let container: AppContainer
    @State private var isAuthenticated = false
    @State private var profileViewModel: ProfileViewModel
    @State private var diaryViewModel: DiaryViewModel
    @State private var logViewModel: LogViewModel
    @State private var statsViewModel: StatsViewModel
    @AppStorage(AppSettingsKeys.hasSeenOnboarding) private var hasSeenOnboarding = false
    @State private var isShowingOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    init(container: AppContainer) {
        self.container = container
        _profileViewModel = State(initialValue: container.makeProfileViewModel())
        _diaryViewModel = State(initialValue: container.makeDiaryViewModel())
        _logViewModel = State(initialValue: container.makeLogViewModel())
        _statsViewModel = State(initialValue: container.makeStatsViewModel())
    }

    var body: some View {
        MainTabView(
            playerViewModel: container.playerViewModel,
            profileViewModel: profileViewModel,
            diaryViewModel: diaryViewModel,
            logViewModel: logViewModel,
            statsViewModel: statsViewModel,
            isAuthenticated: isAuthenticated,
            authService: container.authService,
            onLoginSuccess: { isAuthenticated = true },
            onLogout: logout,
            onProfileDismissed: { showOnboardingIfNeeded() }
        )
        .task {
            isAuthenticated = await container.authService.isAuthenticated
            showOnboardingIfNeeded()
            container.scheduleTasteSnapshotRefresh()
        }
        .sheet(isPresented: $isShowingOnboarding) {
            OnboardingView(
                authService: container.authService,
                onLoginSuccess: {
                    isAuthenticated = true
                    isShowingOnboarding = false
                },
                onDismiss: { isShowingOnboarding = false }
            )
            .presentationDragIndicator(.visible)
        }
        .onChange(of: isShowingOnboarding) { _, isPresented in
            guard !isPresented else { return }
            hasSeenOnboarding = true
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            showOnboardingIfNeeded()
            guard isAuthenticated else { return }
            Task { await container.playerViewModel.refreshNow() }
        }
        .sheet(isPresented: Binding(
            get: { ShortcutCoordinator.shared.isShowingLogCurrentTrack },
            set: { ShortcutCoordinator.shared.isShowingLogCurrentTrack = $0 }
        )) {
            QuickLogCurrentTrackView(
                spotifyRepository: container.spotifyRepository,
                diaryRepository: container.diaryRepository,
                onEntryLogged: {
                    Task {
                        await diaryViewModel.load()
                        await statsViewModel.loadEntries()
                    }
                }
            )
            .presentationDragIndicator(.visible)
        }
    }

    private func showOnboardingIfNeeded() {
        guard !hasSeenOnboarding else { return }
        isShowingOnboarding = true
    }

    private func logout() {
        try? container.authService.logout()
        isAuthenticated = false
        profileViewModel.profile = nil
    }
}
