//
//  StatsHeatmapSection.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import SwiftUI
import Charts

struct StatsHeatmapSection: View {
    let viewModel: StatsViewModel

    var body: some View {
        Section("When You Listen") {
            if viewModel.activityHeatmap.allSatisfy({ $0.count == 0 }) {
                EmptyStateRow(
                    title: "No activity yet",
                    systemImage: "clock",
                    description: Text("Log a track to see which times of day and days of the week you listen most.")
                )
            } else {
                chart
            }
        }
    }

    private func weekdaySymbol(_ weekday: Int) -> String {
        let symbols = Calendar.current.shortStandaloneWeekdaySymbols
        return symbols[(weekday - 1) % symbols.count]
    }

    private func hourBlockLabel(_ start: Int) -> String {
        let end = start + StatsViewModel.heatmapHourBlockSize
        return "\(start)–\(end)"
    }

    private var chart: some View {
        Chart(viewModel.activityHeatmap) { cell in
            RectangleMark(
                x: .value("Time", hourBlockLabel(cell.hourBlockStart)),
                y: .value("Day", weekdaySymbol(cell.weekday))
            )
            .foregroundStyle(by: .value("Entries", cell.count))
            .cornerRadius(4)
        }
        .chartForegroundStyleScale(range: Gradient(colors: [Color.accentColor.opacity(0.08), Color.accentColor]))
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .automatic) {
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(preset: .aligned, values: .automatic) {
                AxisValueLabel()
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .frame(height: 200)
    }
}
