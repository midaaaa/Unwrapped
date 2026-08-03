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

    private var selectedBucket: StatsViewModel.ActivityBucket? {
        viewModel.activityBucket(at: selectedActivityDate)
    }

    private var activityAxisDateFormat: Date.FormatStyle {
        viewModel.activityBucketComponent == .month
            ? .dateTime.month(.abbreviated).year()
            : .dateTime.day().month(.abbreviated)
    }

    var body: some View {
        Section("Activity") {
            if viewModel.activityBuckets.isEmpty {
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
                    Text("\(viewModel.totalEntryCount) entries")
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
        Chart {
            ForEach(viewModel.activityBuckets) { bucket in
                BarMark(
                    x: .value("Date", bucket.date, unit: viewModel.activityBucketComponent),
                    y: .value("Entries", bucket.count)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(6)
                .opacity(selectedBucket == nil || selectedBucket?.id == bucket.id ? 1 : 0.35)
            }
            if let selectedBucket {
                RuleMark(x: .value("Date", selectedBucket.date, unit: viewModel.activityBucketComponent))
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
                                let matched = viewModel.activityBucket(matching: tappedDate)
                                selectedActivityDate = (matched?.id == selectedBucket?.id) ? nil : matched?.date
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
            AxisMarks(values: .automatic(desiredCount: min(viewModel.activityBuckets.count, 4))) {
                AxisTick()
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .frame(height: 160)
    }
}
