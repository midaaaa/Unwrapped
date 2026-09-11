//
//  StatsActivitySection.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import SwiftUI
import Charts

struct StatsActivitySection: View {
    let viewModel: StatsViewModel
    @State private var selectedActivityDate: Date?

    private var selectedBucket: StatsActivityBucket? {
        viewModel.derived.activityBucket(at: selectedActivityDate)
    }

    private var activityAxisDateFormat: Date.FormatStyle {
        viewModel.derived.activityBucketComponent == .month
            ? .dateTime.month(.abbreviated).year()
            : .dateTime.day().month(.abbreviated)
    }

    var body: some View {
        Section("Activity") {
            if viewModel.derived.activityBuckets.isEmpty {
                EmptyStateRow(
                    title: "No activity yet",
                    systemImage: "calendar",
                    description: Text("Log a track to see your activity over time.")
                )
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    readout
                    chart
                }
            }
        }
    }

    private var readout: some View {
        Group {
            if let selectedBucket {
                HStack(spacing: 4) {
                    Text(selectedBucket.date, format: activityAxisDateFormat)
                        .font(.caption.weight(.semibold))
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("\(selectedBucket.count) entries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 4) {
                    Text("\(viewModel.derived.totalEntryCount) entries")
                        .font(.caption.weight(.semibold))
                    Text("total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 16)
    }

    private var chart: some View {
        let buckets = viewModel.derived.activityBuckets
        let component = viewModel.derived.activityBucketComponent
        let selected = selectedBucket

        return Chart {
            ForEach(buckets) { bucket in
                BarMark(
                    x: .value("Date", bucket.date, unit: component),
                    y: .value("Entries", bucket.count)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(6)
                .opacity(selected == nil || selected?.id == bucket.id ? 1 : 0.35)
            }
            if let selected {
                RuleMark(x: .value("Date", selected.date, unit: component))
                    .foregroundStyle(.secondary.opacity(0.3))
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                guard let plotAnchor = proxy.plotFrame else { return }
                                let plotFrame = geometry[plotAnchor]
                                let xPosition = value.location.x - plotFrame.origin.x
                                guard let tappedDate: Date = proxy.value(atX: xPosition) else { return }
                                let matched = viewModel.derived.activityBucket(matching: tappedDate)
                                selectedActivityDate = (matched?.id == selected?.id) ? nil : matched?.date
                            }
                    )
            }
        }
        .chartYAxis {
            AxisMarks {
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: min(buckets.count, 4))) {
                AxisTick()
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .frame(height: 160)
    }
}
