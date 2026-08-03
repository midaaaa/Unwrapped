//
//  StatsTrackRow.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import SwiftUI

struct StatsTrackRow: View {
    let rank: Int
    let track: Track
    var onTap: () -> Void = {}

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text("\(rank)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 20, alignment: .trailing)

                CachedAsyncImage(url: track.albumImageURL, size: 44) {
                    ZStack {
                        Color.secondary.opacity(0.2)
                        Image(systemName: "music.note")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.name)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if track.explicit {
                            ExplicitBadge(colorScheme: colorScheme)
                        }
                        Text(track.artistDisplaySummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
