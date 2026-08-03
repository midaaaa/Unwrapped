//
//  MainTabView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import SwiftUI

enum MainTab: Hashable {
    case diary, log, stats
}

struct MainTabView: View {
    let playerViewModel: PlayerViewModel
    let profileViewModel: ProfileViewModel
    let diaryViewModel: DiaryViewModel
    let logViewModel: LogViewModel
    let statsViewModel: StatsViewModel
    var isAuthenticated: Bool = true
    var authService: SpotifyAuthServiceProtocol?
    var onLoginSuccess: () -> Void = {}
    var onLogout: () -> Void = {}
    var onProfileDismissed: () -> Void = {}

    @State private var showProfile = false
    @State private var showPlayerDetail = false
    @State private var reviewingEntry: DiaryEntry?
    @State private var selectedTab: MainTab = .diary
    @Namespace private var playerNamespace

    var body: some View {
        Group {
            if isAuthenticated {
                tabs.tabViewBottomAccessory {
                    if case .active(let state) = playerViewModel.displayState {
                        PlayerCompactView(
                            state: state,
                            onTap: { showPlayerDetail = true },
                            onTogglePlayback: { playerViewModel.togglePlayback() }
                        )
                        .matchedTransitionSource(id: PlayerCompactView.transitionSourceID, in: playerNamespace)
                    } else {
                        Button(action: {
                            SpotifyDeepLink.openApp()
                        }, label: {
                            HStack {
                                Text("Tap to open Spotify")
                                Image(systemName: "arrow.up.forward")
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(.foreground)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        })
                        .buttonStyle(.plain)
                    }
                }
            } else {
                tabs
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(
                viewModel: profileViewModel,
                isAuthenticated: isAuthenticated,
                authService: authService,
                onLoginSuccess: onLoginSuccess,
                onLogout: onLogout,
                onDataDeleted: {
                    Task { await reloadDiaryAndStats() }
                }
            )
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPlayerDetail) {
            PlayerExpandedView(
                viewModel: playerViewModel,
                namespace: playerNamespace,
                onEntryLogged: {
                    Task { await reloadDiaryAndStats() }
                }
            )
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $reviewingEntry) { entry in
            DiaryEntryDetailView(
                entry: entry,
                makeEditViewModel: { playerViewModel.makeEntryEditorViewModel(existingEntry: entry) },
                onEntryChanged: {
                    Task {
                        await reloadDiaryAndStats()
                        reviewingEntry = diaryViewModel.entries.first { $0.id == entry.id }
                    }
                }
            )
            .presentationDragIndicator(.visible)
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .task(id: isAuthenticated) {
            guard isAuthenticated else { return }
            await playerViewModel.load()
            playerViewModel.startPolling()
        }
        .task(id: isAuthenticated) {
            guard isAuthenticated else { return }
            await profileViewModel.load()
        }
        .onChange(of: isAuthenticated) { _, newValue in
            guard !newValue else { return }
            playerViewModel.stopPolling()
        }
        .onChange(of: showProfile) { _, isPresented in
            guard !isPresented else { return }
            onProfileDismissed()
        }
    }

    private func reloadDiaryAndStats() async {
        await diaryViewModel.load()
        await statsViewModel.loadEntries()
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            Tab("Diary", systemImage: "book.closed", value: MainTab.diary) {
                DiaryView(
                    viewModel: diaryViewModel,
                    profileImageURL: profileViewModel.profile?.imageURL,
                    namespace: playerNamespace,
                    onProfileTap: { showProfile = true },
                    onEntryTap: { reviewingEntry = $0 })
            }
            Tab("Log", systemImage: "plus.circle", value: MainTab.log) {
                LogView(
                    viewModel: logViewModel,
                    profileImageURL: profileViewModel.profile?.imageURL,
                    onProfileTap: { showProfile = true },
                    onEntryLogged: {
                        Task { await reloadDiaryAndStats() }
                    }
                )
            }
            Tab("Stats", systemImage: "chart.xyaxis.line", value: MainTab.stats) {
                StatsView(
                    viewModel: statsViewModel,
                    profileImageURL: profileViewModel.profile?.imageURL,
                    namespace: playerNamespace,
                    onProfileTap: { showProfile = true },
                    onEntryTap: { reviewingEntry = $0 }
                )
            }
        }
    }
}

#if DEBUG
#Preview("Playing") {
    MainTabView(
        playerViewModel: .preview(),
        profileViewModel: .preview(),
        diaryViewModel: .preview(),
        logViewModel: .preview(),
        statsViewModel: .preview()
    )
}

#Preview("Nothing Playing") {
    MainTabView(
        playerViewModel: .preview(currentlyPlaying: .noActivePlayback),
        profileViewModel: .preview(),
        diaryViewModel: .preview(),
        logViewModel: .preview(),
        statsViewModel: .preview()
    )
}
#endif
