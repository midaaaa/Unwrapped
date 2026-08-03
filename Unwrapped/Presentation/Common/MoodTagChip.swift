//
//  MoodTagChip.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import SwiftUI

struct MoodTagChip: View {
    let tag: MoodTag
    let isSelected: Bool
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(tag.emoji)
                Text(tag.label)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.15),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }
}
