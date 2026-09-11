//
//  StatsMoodSection.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import SwiftUI
import Charts

struct StatsMoodSection: View {
    let viewModel: StatsViewModel

    var body: some View {
        Section("Mood") {
            if let message = viewModel.entriesErrorMessage, viewModel.entries.isEmpty {
                EmptyStateRow(
                    title: "Couldn't load mood data",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            } else if viewModel.derived.moodCounts.isEmpty {
                EmptyStateRow(
                    title: "No moods logged yet",
                    systemImage: "face.smiling",
                    description: Text("Tag entries with a mood while logging to see your distribution here.")
                )
            } else {
                chart
            }
        }
    }

    private var chart: some View {
        let moods = viewModel.derived.moodCounts
        let ticks = viewModel.derived.moodAxisTickValues

        return Chart(moods) { item in
            BarMark(
                x: .value("Count", item.count),
                y: .value("Mood", "\(item.tag.emoji) \(item.tag.label)")
            )
            .foregroundStyle(by: .value("Mood", item.tag.label))
            .cornerRadius(6)
        }
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(values: ticks) {
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
        .chartXScale(domain: 0...max(moods.map(\.count).max() ?? 1, 1))
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let plotAnchor = proxy.plotFrame {
                    let plotFrame = geometry[plotAnchor]
                    ForEach(ticks, id: \.self) { tick in
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
        .frame(height: CGFloat(moods.count) * 28 + 28)
    }
}
