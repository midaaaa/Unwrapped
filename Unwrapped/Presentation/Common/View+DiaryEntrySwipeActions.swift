//
//  View+DiaryEntrySwipeActions.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import SwiftUI

extension View {
    @ViewBuilder
    func spotifyDeepLinkSwipeAction(trackID: String?, isCompact: Bool) -> some View {
        if let trackID {
            self.swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    SpotifyDeepLink.openTrack(id: trackID)
                } label: {
                    if isCompact {
                        Image("SpotifyIconSmall")
                            .tint(.spotifyBrand)
                    } else {
                        Label {
                            Text("Open in Spotify")
                        } icon: {
                            Image("SpotifyIconSmall")
                                .tint(.spotifyBrand)
                        }
                    }
                }
            }
        } else {
            self
        }
    }

    func diaryEntrySwipeActions(entry: DiaryEntry, isCompact: Bool, onDelete: @escaping () -> Void) -> some View {
        self
            .spotifyDeepLinkSwipeAction(trackID: entry.track?.id, isCompact: isCompact)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive, action: onDelete) {
                    if isCompact {
                        Image(systemName: "trash")
                    } else {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
    }
}
