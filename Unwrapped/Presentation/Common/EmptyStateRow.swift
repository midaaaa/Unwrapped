//
//  EmptyStateRow.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import SwiftUI

struct EmptyStateRow: View {
    let title: LocalizedStringKey
    let systemImage: String
    let description: Text

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                description
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
