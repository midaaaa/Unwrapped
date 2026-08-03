//
//  DiaryEntryRow.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 26.07.2026.
//

import SwiftUI

struct DiaryEntryRow: View {
    let entry: DiaryEntry
    let namespace: Namespace.ID
    var onTap: () -> Void = {}

    private var heading: String {
        entry.titleOrNoteHeading ?? entry.track?.name ?? String(localized: "Untitled")
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                CachedAsyncImage(url: entry.track?.albumImageURL, size: 44) {
                    ZStack {
                        Color.secondary.opacity(0.2)
                        Image(systemName: "music.note")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(heading)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)

                    if let track = entry.track, track.name != heading {
                        Text(track.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                if !entry.tags.isEmpty {
                    Text(entry.tags.map(\.emoji).joined())
                        .font(.subheadline)
                        .fixedSize()
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: entry.engagementLevel.systemImage)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(entry.loggedAt, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(entry.track == nil)
        .matchedTransitionSource(id: entry.id, in: namespace)
    }
}
