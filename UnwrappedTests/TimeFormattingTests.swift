//
//  TimeFormattingTests.swift
//  UnwrappedTests
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import XCTest
@testable import Unwrapped

final class TimeFormattingTests: XCTestCase {
    // MARK: - formatPlaybackTime

    func test_formatPlaybackTime_underAnHour_usesMinutesSeconds() {
        XCTAssertEqual(formatPlaybackTime(ms: 65_000), "1:05")
    }

    func test_formatPlaybackTime_overAnHour_includesHours() {
        XCTAssertEqual(formatPlaybackTime(ms: 3_665_000), "1:01:05")
    }

    func test_formatPlaybackTime_zero_formatsAsZero() {
        XCTAssertEqual(formatPlaybackTime(ms: 0), "0:00")
    }

    // MARK: - formatDayLabel

    func test_formatDayLabel_today_returnsTodayLabel() {
        XCTAssertEqual(formatDayLabel(Date()), String(localized: "Today"))
    }

    func test_formatDayLabel_yesterday_returnsYesterdayLabel() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertEqual(formatDayLabel(yesterday), String(localized: "Yesterday"))
    }

    func test_formatDayLabel_olderDate_returnsFormattedDayMonth() {
        let older = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let label = formatDayLabel(older)

        XCTAssertNotEqual(label, "Today")
        XCTAssertNotEqual(label, "Yesterday")
        XCTAssertFalse(label.isEmpty)
    }

    // MARK: - roundedToNearestSecond

    func test_roundedToNearestSecond_roundsToClosestWholeSecond() {
        XCTAssertEqual(roundedToNearestSecond(ms: 1_400), 1_000)
        XCTAssertEqual(roundedToNearestSecond(ms: 1_600), 2_000)
    }

    func test_roundedToNearestSecond_withoutClamp_canExceedProvidedValue() {
        XCTAssertEqual(roundedToNearestSecond(ms: 999_600), 1_000_000)
    }

    func test_roundedToNearestSecond_clampsToDuration() {
        XCTAssertEqual(roundedToNearestSecond(ms: 999_600, clampedToDurationMs: 999_000), 999_000)
    }

    func test_roundedToNearestSecond_belowDuration_isNotAffectedByClamp() {
        XCTAssertEqual(roundedToNearestSecond(ms: 1_400, clampedToDurationMs: 999_000), 1_000)
    }
}
