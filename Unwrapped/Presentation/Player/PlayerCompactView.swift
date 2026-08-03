//
//  PlayerCompactView.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import SwiftUI

struct PlayerCompactView: View {
    static let transitionSourceID = "miniPlayer"

    let state: CurrentlyPlayingState
    var onTap: () -> Void = {}
    var onTogglePlayback: () -> Void = {}

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    albumArt(url: state.track.albumImageURL)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.track.name)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            if state.track.explicit {
                                ExplicitBadge(colorScheme: colorScheme)
                            }
                            Text(state.track.artistNames.joined(separator: ", "))
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

            Button(action: onTogglePlayback) {
                Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 15)
    }

    private func albumArt(url: URL?) -> some View {
        CachedAsyncImage(url: url, size: 32) { albumPlaceholder }
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var albumPlaceholder: some View {
        ZStack {
            Color.secondary.opacity(0.2)
            Image(systemName: "music.note")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#if DEBUG
#Preview {
    PlayerCompactView(state: .preview())
        .padding()
}
#endif
