//
//  TimeFormatting.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 25.07.2026.
//

import Foundation

func formatPlaybackTime(ms: Int) -> String {
    let totalSeconds = ms / 1_000
    let hours = totalSeconds / 3_600
    let minutes = (totalSeconds % 3_600) / 60
    let seconds = totalSeconds % 60

    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%d:%02d", minutes, seconds)
}

func formatDayLabel(_ date: Date) -> String {
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
        return String(localized: "Today")
    }
    if calendar.isDateInYesterday(date) {
        return String(localized: "Yesterday")
    }
    return date.formatted(.dateTime.day().month(.abbreviated))
}

func roundedToNearestSecond(ms: Int, clampedToDurationMs durationMs: Int? = nil) -> Int {
    let rounded = Int((Double(ms) / 1_000).rounded()) * 1_000
    guard let durationMs else { return rounded }
    return min(rounded, durationMs)
}
