//
//  DiaryDateRangeFilterSheet.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import SwiftUI

struct DiaryDateRangeFilterSheet: View {
    @Binding var dateRange: ClosedRange<Date>?
    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date
    @State private var endDate: Date

    init(dateRange: Binding<ClosedRange<Date>?>) {
        self._dateRange = dateRange
        let calendar = Calendar.current
        let defaultStart = calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        self._startDate = State(initialValue: dateRange.wrappedValue?.lowerBound ?? defaultStart)
        self._endDate = State(initialValue: dateRange.wrappedValue?.upperBound ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("From", selection: $startDate, displayedComponents: .date)
                DatePicker("To", selection: $endDate, displayedComponents: .date)
            }
            .onChange(of: startDate) { _, newValue in
                if newValue > endDate { endDate = newValue }
            }
            .onChange(of: endDate) { _, newValue in
                if newValue < startDate { startDate = newValue }
            }
            .navigationTitle("Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        apply()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        dateRange = nil
                        dismiss()
                    }
                    .disabled(dateRange == nil)
                }
            }
        }
    }

    private func apply() {
        let calendar = Calendar.current
        let lower = calendar.startOfDay(for: startDate)
        let upper = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        dateRange = lower...upper
    }
}

#if DEBUG
#Preview {
    DiaryDateRangeFilterSheet(dateRange: .constant(nil))
}
#endif
