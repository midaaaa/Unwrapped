//
//  DiaryBrowsingTests.swift
//  UnwrappedTests
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import XCTest
@testable import Unwrapped

@MainActor
final class DiaryBrowsingTests: XCTestCase {
    func test_availableFields_entriesMode_onlyDate() {
        XCTAssertEqual(DiarySortField.availableFields(for: .entries), [.date])
    }

    func test_availableFields_tracksMode_allThreeFields() {
        XCTAssertEqual(DiarySortField.availableFields(for: .tracks), [.date, .count, .name])
    }

    func test_availableFields_artistsMode_allThreeFields() {
        XCTAssertEqual(DiarySortField.availableFields(for: .artists), [.date, .count, .name])
    }

    func test_defaultDirection_dateAndCountDescendNameAscends() {
        XCTAssertEqual(DiarySortField.date.defaultDirection, .descending)
        XCTAssertEqual(DiarySortField.count.defaultDirection, .descending)
        XCTAssertEqual(DiarySortField.name.defaultDirection, .ascending)
    }

    func test_toggled_flipsDirection() {
        XCTAssertEqual(DiarySortDirection.ascending.toggled, .descending)
        XCTAssertEqual(DiarySortDirection.descending.toggled, .ascending)
    }
}
