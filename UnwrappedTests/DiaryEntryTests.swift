//
//  DiaryEntryTests.swift
//  UnwrappedTests
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import XCTest
@testable import Unwrapped

final class DiaryEntryTests: XCTestCase {
    private func entry(title: String?, note: String?) -> DiaryEntry {
        DiaryEntry(
            id: UUID(),
            loggedAt: Date(),
            playedAt: Date(),
            engagementLevel: .detailed,
            tags: [],
            title: title,
            note: note,
            progressMs: nil,
            track: nil
        )
    }

    func test_titleOrNoteHeading_prefersNonEmptyTitle() {
        XCTAssertEqual(entry(title: "My Title", note: "Some note").titleOrNoteHeading, "My Title")
    }

    func test_titleOrNoteHeading_emptyTitle_fallsBackToNoteFirstLine() {
        XCTAssertEqual(entry(title: "", note: "First line\nSecond line").titleOrNoteHeading, "First line")
    }

    func test_titleOrNoteHeading_nilTitle_usesNoteFirstLine() {
        XCTAssertEqual(entry(title: nil, note: "Only line").titleOrNoteHeading, "Only line")
    }

    func test_titleOrNoteHeading_noTitleNoNote_returnsNil() {
        XCTAssertNil(entry(title: nil, note: nil).titleOrNoteHeading)
    }

    func test_titleOrNoteHeading_emptyTitleAndEmptyNote_returnsNil() {
        XCTAssertNil(entry(title: "", note: "").titleOrNoteHeading)
    }
}
