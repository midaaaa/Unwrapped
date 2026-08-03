//
//  StatsGenreSection.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import SwiftUI
import Charts

struct StatsGenreSection: View {
    let viewModel: StatsViewModel

    var body: some View {
        Section("Genres") {
            if viewModel.genreBreakdownIsLoading && viewModel.genreCounts.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 8)
            } else if viewModel.genreCounts.isEmpty {
                EmptyStateRow(
                    title: "No genres yet",
                    systemImage: "guitars",
                    description: Text("Log tracks to see which genres you reach for most.")
                )
            } else {
                chart
            }
        }
    }

    private var chart: some View {
        Chart(viewModel.genreCounts) { item in
            BarMark(
                x: .value("Count", item.count),
                y: .value("Genre", item.genre.capitalized)
            )
            .foregroundStyle(by: .value("Genre", item.genre.capitalized))
            .cornerRadius(6)
        }
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(values: viewModel.genreAxisTickValues) {
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label).fixedSize()
                    }
                }
            }
        }
        .chartXScale(domain: 0...max(viewModel.genreCounts.map(\.count).max() ?? 1, 1))
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let plotAnchor = proxy.plotFrame {
                    let plotFrame = geometry[plotAnchor]
                    ForEach(viewModel.genreAxisTickValues, id: \.self) { tick in
                        if let x = proxy.position(forX: tick) {
                            Text("\(tick)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize()
                                .position(x: plotFrame.minX + x, y: plotFrame.maxY + 12)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .frame(height: CGFloat(viewModel.genreCounts.count) * 28 + 28)
    }
}
