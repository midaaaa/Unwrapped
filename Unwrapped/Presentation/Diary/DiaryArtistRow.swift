//
//  DiaryArtistRow.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import SwiftUI

struct DiaryArtistRow: View {
    let summary: DiaryArtistSummary
    var onTap: () -> Void = {}
    var fetchImageIfNeeded: (DiaryArtistSummary) async -> Void = { _ in }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                CachedAsyncImage(url: summary.imageURL, size: 44, sizing: .fixedSquare) {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .foregroundStyle(.secondary)
                }
                .clipShape(Circle())
                .task(id: summary.id) { await fetchImageIfNeeded(summary) }

                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.artistName)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    Text("\(Text("\(summary.trackCount) tracks")) · \(Text("\(summary.entryCount) entries"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(summary.lastLoggedAt, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
