//
//  TimelineActiveEntryResolverTests.swift
//  UnwrappedTests
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import XCTest
@testable import Unwrapped

final class TimelineActiveEntryResolverTests: XCTestCase {
    private func entry(progressMs: Int?, loggedAt: Date = Date()) -> DiaryEntry {
        DiaryEntry(
            id: UUID(),
            loggedAt: loggedAt,
            playedAt: loggedAt,
            engagementLevel: .quickTap,
            tags: [],
            title: nil,
            note: nil,
            progressMs: progressMs,
            track: nil
        )
    }

    // MARK: - sorted

    func test_sorted_ordersByProgressAscending() {
        let a = entry(progressMs: 3000)
        let b = entry(progressMs: 1000)
        let c = entry(progressMs: 2000)

        XCTAssertEqual(TimelineActiveEntryResolver.sorted([a, b, c]).map(\.id), [b.id, c.id, a.id])
    }

    func test_sorted_tieBreaksBySameProgressUsingLoggedAt() {
        let now = Date()
        let earlier = entry(progressMs: 1000, loggedAt: now.addingTimeInterval(-100))
        let later = entry(progressMs: 1000, loggedAt: now)

        XCTAssertEqual(TimelineActiveEntryResolver.sorted([later, earlier]).map(\.id), [earlier.id, later.id])
    }

    func test_sorted_nilProgressTreatedAsZero() {
        let noProgress = entry(progressMs: nil)
        let hasProgress = entry(progressMs: 500)

        XCTAssertEqual(TimelineActiveEntryResolver.sorted([hasProgress, noProgress]).map(\.id), [noProgress.id, hasProgress.id])
    }

    // MARK: - activeEntry

    func test_activeEntry_progressWithinWindow_returnsEntryAndRemainingTime() {
        let onlyEntry = entry(progressMs: 1000)
        let sorted = TimelineActiveEntryResolver.sorted([onlyEntry])

        let result = TimelineActiveEntryResolver.activeEntry(in: sorted, atProgressMs: 1500, windowMs: 1000)

        XCTAssertEqual(result?.id, onlyEntry.id)
        XCTAssertEqual(result?.remainingMs, 500)
    }

    func test_activeEntry_progressBeforeEntry_returnsNil() {
        let onlyEntry = entry(progressMs: 1000)
        let sorted = TimelineActiveEntryResolver.sorted([onlyEntry])

        XCTAssertNil(TimelineActiveEntryResolver.activeEntry(in: sorted, atProgressMs: 500, windowMs: 1000))
    }

    func test_activeEntry_progressAtWindowEnd_isExclusiveAndReturnsNil() {
        let onlyEntry = entry(progressMs: 1000)
        let sorted = TimelineActiveEntryResolver.sorted([onlyEntry])

        XCTAssertNil(TimelineActiveEntryResolver.activeEntry(in: sorted, atProgressMs: 2000, windowMs: 1000))
    }

    func test_activeEntry_duplicateProgress_onlyFirstIsConsidered() {
        let now = Date()
        let first = entry(progressMs: 1000, loggedAt: now.addingTimeInterval(-10))
        let duplicate = entry(progressMs: 1000, loggedAt: now)
        let sorted = TimelineActiveEntryResolver.sorted([first, duplicate])

        let result = TimelineActiveEntryResolver.activeEntry(in: sorted, atProgressMs: 1200, windowMs: 1000)

        XCTAssertEqual(result?.id, first.id)
    }

    func test_activeEntry_secondEntryStartsBeforeFirstWindowEnds_isSuppressed() {
        let firstEntry = entry(progressMs: 0)
        let secondEntry = entry(progressMs: 1000)
        let sorted = TimelineActiveEntryResolver.sorted([firstEntry, secondEntry])

        let withinFirstWindow = TimelineActiveEntryResolver.activeEntry(in: sorted, atProgressMs: 1500, windowMs: 2000)
        XCTAssertEqual(withinFirstWindow?.id, firstEntry.id, "the earlier entry's window should still win")

        let afterBothWindows = TimelineActiveEntryResolver.activeEntry(in: sorted, atProgressMs: 2500, windowMs: 2000)
        XCTAssertNil(afterBothWindows, "second entry's window was suppressed, so nothing should claim this position")
    }

    func test_activeEntry_nonOverlappingEntries_secondClaimsItsOwnWindow() {
        let firstEntry = entry(progressMs: 0)
        let secondEntry = entry(progressMs: 2000)
        let sorted = TimelineActiveEntryResolver.sorted([firstEntry, secondEntry])

        let result = TimelineActiveEntryResolver.activeEntry(in: sorted, atProgressMs: 2500, windowMs: 1000)

        XCTAssertEqual(result?.id, secondEntry.id)
        XCTAssertEqual(result?.remainingMs, 500)
    }

    func test_activeEntryID_returnsOnlyTheIdentifier() {
        let onlyEntry = entry(progressMs: 0)
        let sorted = TimelineActiveEntryResolver.sorted([onlyEntry])

        XCTAssertEqual(TimelineActiveEntryResolver.activeEntryID(in: sorted, atProgressMs: 100, windowMs: 1000), onlyEntry.id)
    }

    func test_activeEntry_emptyEntries_returnsNil() {
        XCTAssertNil(TimelineActiveEntryResolver.activeEntry(in: [], atProgressMs: 0, windowMs: 1000))
    }
}
