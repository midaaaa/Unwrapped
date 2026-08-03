//
//  StatsRecapSection.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import SwiftUI

struct StatsRecapSection: View {
    @Bindable var viewModel: StatsViewModel

    var body: some View {
        Group {
            Picker("Recap Period", selection: Binding(
                get: { viewModel.recapPeriod },
                set: { newValue in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.recapPeriod = newValue
                    }
                }
            )) {
                ForEach(RecapPeriod.allCases) { period in
                    Text(period.label).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)

            content
                .padding(.bottom, 16)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                .animation(.easeInOut(duration: 0.25), value: viewModel.recapState)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.recapState {
        case .insufficientData(let entriesNeeded, let daysRemaining):
            placeholder(entriesNeeded: entriesNeeded, daysRemaining: daysRemaining)
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
        case .ready(let layout):
            cardsGrid(layout)
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
        }
    }

    private func cardsGrid(_ layout: RecapCardLayout) -> some View {
        VStack(spacing: 14) {
            if let topWide = layout.topWide {
                RecapCardView(card: topWide, style: .wide)
            }
            if layout.narrowLeft != nil || layout.narrowRight != nil {
                HStack(spacing: 14) {
                    if let narrowLeft = layout.narrowLeft {
                        RecapCardView(card: narrowLeft, style: .compact)
                    }
                    if let narrowRight = layout.narrowRight {
                        RecapCardView(card: narrowRight, style: .compact)
                    }
                }
            }
            if let bottomWide = layout.bottomWide {
                RecapCardView(card: bottomWide, style: .wide)
            }
        }
        .padding(.horizontal, 16)
    }

    private func placeholder(entriesNeeded: Int, daysRemaining: Int) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "wand.and.sparkles")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Recap unlocks soon")
                    .font(.subheadline.weight(.semibold))
                Text(placeholderMessage(entriesNeeded: entriesNeeded, daysRemaining: daysRemaining))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private func placeholderMessage(entriesNeeded: Int, daysRemaining: Int) -> String {
        if entriesNeeded > 0 {
            return String(localized: "Log \(entriesNeeded) more entries to unlock it")
        }
        return String(localized: "Check back in \(daysRemaining) days")
    }
}

#if DEBUG
private struct RecapPreviewContainer: View {
    let viewModel: StatsViewModel

    var body: some View {
        List {
            Section("Recap") {
                StatsRecapSection(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadEntries()
            await viewModel.loadRecapSnapshots()
        }
    }
}

#Preview("Comparison") {
    RecapPreviewContainer(viewModel: .previewRecapFull())
}

#Preview("Highlights Only") {
    RecapPreviewContainer(viewModel: .previewRecapNoHistory())
}

#Preview("Sparse") {
    RecapPreviewContainer(viewModel: .previewRecapSparse())
}
#endif
