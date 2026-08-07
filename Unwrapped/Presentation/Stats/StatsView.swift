//
//  StatsView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import SwiftUI

struct StatsView: View {
    @Bindable var viewModel: StatsViewModel
    var profileImageURL: URL?
    let namespace: Namespace.ID
    var onProfileTap: () -> Void = {}
    var onEntryTap: (DiaryEntry) -> Void = { _ in }

    @State private var scopedTarget: StatsScope?
    @State private var revealedEntryCount = 0
    @State private var revealedTrackCount = 0
    @State private var revealedArtistCount = 0

    private func revealSummaryCounts() {
        revealedEntryCount = viewModel.totalEntryCount
        revealedTrackCount = viewModel.distinctTrackCount
        revealedArtistCount = viewModel.distinctArtistCount
    }

    private func resetSummaryCounts() {
        revealedEntryCount = 0
        revealedTrackCount = 0
        revealedArtistCount = 0
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Recap") {
                    StatsRecapSection(viewModel: viewModel)
                }
                Section("Period") {
                    periodPicker
                    summaryTiles
                }
                StatsInsightsSection(viewModel: viewModel)
                StatsMoodSection(viewModel: viewModel)
                StatsActivitySection(viewModel: viewModel)
                StatsHeatmapSection(viewModel: viewModel)
                StatsGenreSection(viewModel: viewModel)
                topTracksSection
                topArtistsSection
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileAvatarButton(imageURL: profileImageURL, onTap: onProfileTap)
                }
            }
            .task {
                await viewModel.loadEntries()
                revealSummaryCounts()
                await viewModel.loadGenreBreakdown()
            }
            .task(id: viewModel.timeRange) {
                await viewModel.loadTopItems()
                revealSummaryCounts()
                await viewModel.loadGenreBreakdown()
            }
            .task {
                await viewModel.loadRecapSnapshots()
            }
            .refreshable {
                resetSummaryCounts()
                await viewModel.loadEntries()
                await viewModel.loadTopItems()
                await viewModel.loadRecapSnapshots()
                await viewModel.loadGenreBreakdown()
                revealSummaryCounts()
            }
            .onChange(of: viewModel.entries) { _, _ in
                revealSummaryCounts()
            }
            .navigationDestination(item: $scopedTarget) { target in
                DiaryScopedEntriesView(
                    title: target.name,
                    entries: target.entries(in: viewModel),
                    namespace: namespace,
                    onEntryTap: onEntryTap,
                    showsDeleteAction: false
                )
            }
        }
    }

    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.timeRange) {
            ForEach(TopItemsTimeRange.allCases, id: \.self) { range in
                Text(range.label).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .listRowSeparator(.hidden)
    }

    private var summaryTiles: some View {
        HStack(spacing: 0) {
            StatTile(value: revealedEntryCount, noun: "\(viewModel.totalEntryCount) entries")
            Divider()
            StatTile(value: revealedTrackCount, noun: "\(viewModel.distinctTrackCount) tracks")
            Divider()
            StatTile(value: revealedArtistCount, noun: "\(viewModel.distinctArtistCount) artists")
        }
    }

    // MARK: - Top tracks / artists

    @ViewBuilder
    private var topTracksSection: some View {
        Section("Top Tracks") {
            if viewModel.isUnauthenticated {
                EmptyStateRow(
                    title: "Sign in Required",
                    systemImage: "wifi.slash",
                    description: Text("Sign in with Spotify to see your top tracks.")
                )
            } else if viewModel.isTopItemsRegionRestricted {
                EmptyStateRow(
                    title: "Not Available in Your Region",
                    systemImage: "hand.raised.slash",
                    description: Text("Spotify is blocking this request from your location.")
                )
            } else if let message = viewModel.topItemsErrorMessage, viewModel.topTracks.isEmpty {
                EmptyStateRow(
                    title: "Couldn't load top tracks",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            } else if viewModel.topTracks.isEmpty {
                EmptyStateRow(
                    title: "Nothing here yet",
                    systemImage: "music.note.list",
                    description: Text("Keep listening — your top tracks for this period will show up here.")
                )
            } else {
                ForEach(Array(viewModel.topTracks.enumerated()), id: \.element.id) { index, track in
                    StatsTrackRow(rank: index + 1, track: track, onTap: { scopedTarget = .track(id: track.id, name: track.name) })
                        .spotifyDeepLinkSwipeAction(trackID: track.id, isCompact: true)
                }
            }
        }
    }

    @ViewBuilder
    private var topArtistsSection: some View {
        Section("Top Artists") {
            if viewModel.isUnauthenticated {
                EmptyStateRow(
                    title: "Sign in Required",
                    systemImage: "wifi.slash",
                    description: Text("Sign in with Spotify to see your top artists.")
                )
            } else if viewModel.isTopItemsRegionRestricted {
                EmptyStateRow(
                    title: "Not Available in Your Region",
                    systemImage: "hand.raised.slash",
                    description: Text("Spotify is blocking this request from your location.")
                )
            } else if let message = viewModel.topItemsErrorMessage, viewModel.topArtists.isEmpty {
                EmptyStateRow(
                    title: "Couldn't load top artists",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            } else if viewModel.topArtists.isEmpty {
                EmptyStateRow(
                    title: "Nothing here yet",
                    systemImage: "music.mic",
                    description: Text("Keep listening — your top artists for this period will show up here.")
                )
            } else {
                ForEach(Array(viewModel.topArtists.enumerated()), id: \.element.id) { index, artist in
                    StatsArtistRow(rank: index + 1, artist: artist, onTap: { scopedTarget = .artist(id: artist.id, name: artist.name) })
                }
            }
        }
    }
}

#if DEBUG
#Preview("Populated") {
    StatsPreviewContainer(viewModel: .preview())
}

#Preview("Empty") {
    StatsPreviewContainer(viewModel: .previewEmpty())
}

#Preview("Signed Out") {
    StatsPreviewContainer(viewModel: .previewUnauthenticated())
}

private struct StatsPreviewContainer: View {
    let viewModel: StatsViewModel
    @Namespace private var namespace

    var body: some View {
        StatsView(viewModel: viewModel, namespace: namespace)
    }
}
#endif
