//
//  DiaryFilterTests.swift
//  UnwrappedTests
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import XCTest
@testable import Unwrapped

final class DiaryFilterTests: XCTestCase {
    private func entry(
        kind: EngagementLevel = .detailed,
        tags: [MoodTag] = [],
        loggedAt: Date = Date()
    ) -> DiaryEntry {
        DiaryEntry(
            id: UUID(),
            loggedAt: loggedAt,
            playedAt: loggedAt,
            engagementLevel: kind,
            tags: tags,
            title: nil,
            note: nil,
            progressMs: nil,
            track: nil
        )
    }

    func test_defaultFilter_isNotActive() {
        XCTAssertFalse(DiaryFilter().isActive)
    }

    func test_defaultFilter_matchesAnyEntry() {
        let filter = DiaryFilter()
        XCTAssertTrue(filter.matches(entry(kind: .quickTap)))
        XCTAssertTrue(filter.matches(entry(kind: .detailed, tags: [.happy])))
    }

    func test_kindsFilter_excludesOtherKind() {
        var filter = DiaryFilter()
        filter.kinds = [.detailed]
        XCTAssertTrue(filter.isActive)
        XCTAssertTrue(filter.matches(entry(kind: .detailed)))
        XCTAssertFalse(filter.matches(entry(kind: .quickTap)))
    }

    func test_moodTagFilter_requiresAtLeastOneOverlappingTag() {
        var filter = DiaryFilter()
        filter.moodTags = [.happy, .calm]
        XCTAssertTrue(filter.isActive)
        XCTAssertTrue(filter.matches(entry(tags: [.calm, .sad])))
        XCTAssertFalse(filter.matches(entry(tags: [.sad])))
        XCTAssertFalse(filter.matches(entry(tags: [])))
    }

    func test_dateRangeFilter_excludesEntriesOutsideRange() {
        let now = Date()
        var filter = DiaryFilter()
        filter.dateRange = now...(now.addingTimeInterval(60 * 60))
        XCTAssertTrue(filter.isActive)
        XCTAssertTrue(filter.matches(entry(loggedAt: now.addingTimeInterval(30 * 60))))
        XCTAssertFalse(filter.matches(entry(loggedAt: now.addingTimeInterval(-30 * 60))))
        XCTAssertFalse(filter.matches(entry(loggedAt: now.addingTimeInterval(2 * 60 * 60))))
    }

    func test_combinedFilters_allMustMatch() {
        var filter = DiaryFilter()
        filter.kinds = [.detailed]
        filter.moodTags = [.happy]
        let matching = entry(kind: .detailed, tags: [.happy])
        let wrongKind = entry(kind: .quickTap, tags: [.happy])
        let wrongTag = entry(kind: .detailed, tags: [.sad])

        XCTAssertTrue(filter.matches(matching))
        XCTAssertFalse(filter.matches(wrongKind))
        XCTAssertFalse(filter.matches(wrongTag))
    }
}
