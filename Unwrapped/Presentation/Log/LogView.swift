//
//  LogView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import SwiftUI

struct LogView: View {
    let viewModel: LogViewModel
    var profileImageURL: URL?
    var onProfileTap: () -> Void = {}
    var onEntryLogged: () -> Void = {}

    @State private var entryEditorViewModel: EntryEditorViewModel?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Log")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProfileAvatarButton(imageURL: profileImageURL, onTap: onProfileTap)
                    }
                }
                .task {
                    await viewModel.load()
                }
                .sheet(item: $entryEditorViewModel) { entryEditorViewModel in
                    EntryEditorView(
                        viewModel: entryEditorViewModel,
                        onSave: onEntryLogged,
                        onDelete: onEntryLogged
                    )
                    .presentationDragIndicator(.visible)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.recentlyPlayed.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                if viewModel.isUnauthenticated {
                    EmptyStateRow(
                        title: "Sign in Required",
                        systemImage: "wifi.slash",
                        description: Text("Sign in with Spotify to see your recently played tracks.")
                    )
                } else if let errorMessage = viewModel.errorMessage, viewModel.recentlyPlayed.isEmpty {
                    EmptyStateRow(
                        title: "Couldn't load recently played",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if viewModel.recentlyPlayed.isEmpty {
                    EmptyStateRow(
                        title: "Nothing here yet",
                        systemImage: "magnifyingglass",
                        description: Text("Recently played tracks will show up here, or search for one to log.")
                    )
                } else {
                    ForEach(viewModel.recentlyPlayed) { item in
                        RecentlyPlayedRow(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                entryEditorViewModel = viewModel.makeEntryEditorViewModel(for: item)
                            }
                            .listSectionSeparator(.hidden, edges: [.top, .bottom])
                            .spotifyDeepLinkSwipeAction(trackID: item.track.id, isCompact: true)
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.load()
            }
        }
    }
}

private struct RecentlyPlayedRow: View {
    let item: RecentlyPlayedItem

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            albumArt

            VStack(alignment: .leading, spacing: 2) {
                Text(item.track.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if item.track.explicit {
                        ExplicitBadge(colorScheme: colorScheme)
                    }
                    Text(item.track.artistNames.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Text(item.playedAt, format: .relative(presentation: .named))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var albumArt: some View {
        CachedAsyncImage(url: item.track.albumImageURL, size: 44) {
            ZStack {
                Color.secondary.opacity(0.2)
                Image(systemName: "music.note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#if DEBUG
private struct LogPreviewContainer: View {
    let viewModel: LogViewModel
    @State private var showProfile = false

    var body: some View {
        LogView(viewModel: viewModel, onProfileTap: { showProfile = true })
            .sheet(isPresented: $showProfile) {
                ProfileView(viewModel: .preview(), onLogout: {})
            }
    }
}

#Preview("With Items") {
    LogPreviewContainer(viewModel: .preview())
}

#Preview("Empty") {
    LogPreviewContainer(viewModel: .previewEmpty())
}

#Preview("Loading") {
    LogPreviewContainer(viewModel: .previewLoading())
}
#endif
