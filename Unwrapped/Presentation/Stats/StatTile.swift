//
//  StatTile.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import SwiftUI

struct StatTile: View {
    let value: Int
    let noun: LocalizedStringResource

    private var word: String {
        let resolved = String(localized: noun)
        guard let spaceIndex = resolved.firstIndex(of: " ") else { return resolved }
        return String(resolved[resolved.index(after: spaceIndex)...])
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(value, format: .number)
                .font(.title2.bold())
                .contentTransition(.numericText(value: Double(value)))
                .animation(.easeInOut(duration: 0.25), value: value)
            Text(word)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
