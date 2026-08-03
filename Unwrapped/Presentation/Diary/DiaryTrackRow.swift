//
//  DiaryTrackRow.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import SwiftUI

struct DiaryTrackRow: View {
    let summary: DiaryTrackSummary
    var onTap: () -> Void = {}

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                CachedAsyncImage(url: summary.track.albumImageURL, size: 44) {
                    ZStack {
                        Color.secondary.opacity(0.2)
                        Image(systemName: "music.note")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.track.name)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if summary.track.explicit {
                            ExplicitBadge(colorScheme: colorScheme)
                        }
                        Text(summary.track.artistDisplaySummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(summary.entryCount) entries")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(summary.lastLoggedAt, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
