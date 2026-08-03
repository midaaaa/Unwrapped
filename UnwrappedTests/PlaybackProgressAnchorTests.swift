//
//  PlaybackProgressAnchorTests.swift
//  UnwrappedTests
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import XCTest
@testable import Unwrapped

final class PlaybackProgressAnchorTests: XCTestCase {
    func test_progressMs_whilePlaying_addsElapsedTimeSinceReference() {
        let reference = Date()
        let anchor = PlaybackProgressAnchor(baseProgressMs: 1000, referenceDate: reference, isPlaying: true, durationMs: 300_000)

        let result = anchor.progressMs(at: reference.addingTimeInterval(2))

        XCTAssertEqual(result, 3000)
    }

    func test_progressMs_whenPaused_ignoresElapsedTimeAndReturnsBaseProgress() {
        let reference = Date()
        let anchor = PlaybackProgressAnchor(baseProgressMs: 5000, referenceDate: reference, isPlaying: false, durationMs: 300_000)

        let result = anchor.progressMs(at: reference.addingTimeInterval(60))

        XCTAssertEqual(result, 5000)
    }

    func test_progressMs_clampsAtTrackDuration() {
        let reference = Date()
        let anchor = PlaybackProgressAnchor(baseProgressMs: 0, referenceDate: reference, isPlaying: true, durationMs: 10_000)

        let result = anchor.progressMs(at: reference.addingTimeInterval(30))

        XCTAssertEqual(result, 10_000)
    }

    func test_progressMs_atExactReferenceDate_returnsBaseProgress() {
        let reference = Date()
        let anchor = PlaybackProgressAnchor(baseProgressMs: 2500, referenceDate: reference, isPlaying: true, durationMs: 300_000)

        XCTAssertEqual(anchor.progressMs(at: reference), 2500)
    }
}
