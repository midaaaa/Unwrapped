//
//  StatsArtistRow.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import SwiftUI

struct StatsArtistRow: View {
    let rank: Int
    let artist: Artist
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text("\(rank)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 20, alignment: .trailing)

                CachedAsyncImage(url: artist.imageURL, size: 44, sizing: .fixedSquare) {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .foregroundStyle(.secondary)
                }
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(artist.name)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    if let genre = artist.genres.first {
                        Text(genre.capitalized)
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
