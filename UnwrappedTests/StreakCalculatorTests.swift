//
//  StreakCalculatorTests.swift
//  UnwrappedTests
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import XCTest
@testable import Unwrapped

final class StreakCalculatorTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ daysAgo: Int, from reference: Date) -> Date {
        calendar.date(byAdding: .day, value: -daysAgo, to: reference)!
    }

    func test_currentStreak_emptyDates_returnsZero() {
        XCTAssertEqual(StreakCalculator.currentStreak(loggedDates: [], calendar: calendar), 0)
    }

    func test_currentStreak_loggedToday_countsConsecutiveDaysEndingToday() {
        let now = Date()
        let dates = [date(0, from: now), date(1, from: now), date(2, from: now)]
        XCTAssertEqual(StreakCalculator.currentStreak(loggedDates: dates, calendar: calendar, referenceDate: now), 3)
    }

    func test_currentStreak_gapBreaksStreak() {
        let now = Date()
        let dates = [date(0, from: now), date(1, from: now), date(3, from: now)]
        XCTAssertEqual(StreakCalculator.currentStreak(loggedDates: dates, calendar: calendar, referenceDate: now), 2)
    }

    func test_currentStreak_missedTodayButLoggedYesterday_countsFromYesterday() {
        let now = Date()
        let dates = [date(1, from: now), date(2, from: now)]
        XCTAssertEqual(StreakCalculator.currentStreak(loggedDates: dates, calendar: calendar, referenceDate: now), 2)
    }

    func test_currentStreak_missedTodayAndYesterday_returnsZero() {
        let now = Date()
        let dates = [date(2, from: now)]
        XCTAssertEqual(StreakCalculator.currentStreak(loggedDates: dates, calendar: calendar, referenceDate: now), 0)
    }

    func test_longestStreak_emptyDates_returnsZero() {
        XCTAssertEqual(StreakCalculator.longestStreak(loggedDates: [], calendar: calendar), 0)
    }

    func test_longestStreak_singleDate_returnsOne() {
        XCTAssertEqual(StreakCalculator.longestStreak(loggedDates: [Date()], calendar: calendar), 1)
    }

    func test_longestStreak_findsLongestRunEvenWithLaterGaps() {
        let now = Date()
        // 5 consecutive days, then a gap, then 2 consecutive days
        let dates = (0..<5).map { date($0, from: now) } + [date(10, from: now), date(11, from: now)]
        XCTAssertEqual(StreakCalculator.longestStreak(loggedDates: dates, calendar: calendar), 5)
    }

    func test_longestStreak_duplicateDatesOnSameDayCountOnce() {
        let now = Date()
        let sameDayTwice = calendar.date(byAdding: .hour, value: 3, to: now)!
        let dates = [now, sameDayTwice, date(1, from: now)]
        XCTAssertEqual(StreakCalculator.longestStreak(loggedDates: dates, calendar: calendar), 2)
    }
}
