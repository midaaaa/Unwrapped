//
//  StreakCalculator.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import Foundation

enum StreakCalculator {
    static func currentStreak(loggedDates: [Date], calendar: Calendar = .current, referenceDate: Date = .now) -> Int {
        let loggedDays = Set(loggedDates.map { calendar.startOfDay(for: $0) })
        let today = calendar.startOfDay(for: referenceDate)
        guard !loggedDays.isEmpty else { return 0 }

        var streak = 0
        var day = loggedDays.contains(today) ? today : calendar.date(byAdding: .day, value: -1, to: today)!
        while loggedDays.contains(day) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }
        return streak
    }

    static func longestStreak(loggedDates: [Date], calendar: Calendar = .current) -> Int {
        let loggedDays = Set(loggedDates.map { calendar.startOfDay(for: $0) }).sorted()
        guard !loggedDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1
        for index in 1..<loggedDays.count {
            let dayGap = calendar.dateComponents([.day], from: loggedDays[index - 1], to: loggedDays[index]).day ?? 0
            current = dayGap == 1 ? current + 1 : 1
            longest = max(longest, current)
        }
        return longest
    }
}
