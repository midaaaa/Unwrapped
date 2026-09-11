//
//  StatsInsightsSection.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import SwiftUI

struct StatsInsightsSection: View {
    let viewModel: StatsViewModel

    var body: some View {
        Section("Insights") {
            if !hasAnyInsight {
                EmptyStateRow(
                    title: "Nothing to show yet",
                    systemImage: "sparkle.magnifyingglass",
                    description: Text("Keep logging — patterns show up here once there's enough history.")
                )
            } else {
                streakRow
                discoveryRow
                replayedRow
                mismatchRow
                ForEach(viewModel.derived.engagementMoodBreakdown) { engagementRow($0) }
            }
        }
    }

    private var hasAnyInsight: Bool {
        viewModel.derived.currentStreak > 0
            || viewModel.derived.discoveryRate != nil
            || viewModel.derived.mostReplayedTrack != nil
            || viewModel.derived.topArtistMismatch != nil
            || !viewModel.derived.engagementMoodBreakdown.isEmpty
    }

    @ViewBuilder
    private var streakRow: some View {
        if viewModel.derived.currentStreak > 0 {
            insightRow(systemImage: "flame.fill", tint: .red) {
                Text("Streak")
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    Text("\(viewModel.derived.currentStreak) days")
                    if viewModel.derived.longestStreak > viewModel.derived.currentStreak {
                        Text("·")
                        Text("Best")
                        Text("\(viewModel.derived.longestStreak) days")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var discoveryRow: some View {
        if let rate = viewModel.derived.discoveryRate {
            insightRow(systemImage: "sparkles", tint: .purple) {
                Text("\(rate.formatted(.percent.precision(.fractionLength(0)))) new artists")
                    .font(.subheadline.weight(.medium))
                Text("Of the artists you logged this period")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var replayedRow: some View {
        if let replayed = viewModel.derived.mostReplayedTrack {
            HStack(spacing: 12) {
                CachedAsyncImage(url: replayed.track.albumImageURL, size: 36, sizing: .fixedSquare) {
                    Image(systemName: "music.note")
                        .font(.system(size: 16))
                        .foregroundStyle(.pink)
                        .frame(width: 36, height: 36)
                        .background(Color.pink.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(replayed.track.name)
                        .font(.subheadline.weight(.medium))
                    Text("Logged \(replayed.count) times · Most replayed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var mismatchRow: some View {
        if let mismatch = viewModel.derived.topArtistMismatch {
            insightRow(systemImage: "arrow.left.arrow.right", tint: .blue) {
                Text("Spotify says \(mismatch.spotifyTop.name)")
                    .font(.subheadline.weight(.medium))
                Text("But you logged \(mismatch.diaryTopName) most (\(mismatch.diaryTopCount)×)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func engagementRow(_ row: StatsEngagementRow) -> some View {
        insightRow(systemImage: row.level.systemImage, tint: .indigo) {
            if row.level == .quickTap {
                Text("\(row.count) reactions")
                    .font(.subheadline.weight(.medium))
            } else {
                Text("\(row.count) entries")
                    .font(.subheadline.weight(.medium))
            }
        }
    }

    @ViewBuilder
    private func insightRow(
        systemImage: String,
        tint: Color,
        @ViewBuilder content: () -> some View
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                content()
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}
