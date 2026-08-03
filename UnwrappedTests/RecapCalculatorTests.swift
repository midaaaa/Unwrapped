//
//  RecapCalculatorTests.swift
//  UnwrappedTests
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import XCTest
@testable import Unwrapped

@MainActor
final class RecapCalculatorTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func track(id: String = "t1", name: String = "Song", artist: String = "Artist") -> Track {
        Track(
            id: id,
            name: name,
            artistNames: [artist],
            artistIds: ["a-\(id)"],
            albumName: "Album",
            durationMs: 200_000,
            explicit: false,
            uri: "spotify:track:\(id)"
        )
    }

    private func entry(
        loggedAt: Date,
        tags: [MoodTag] = [],
        track: Track? = nil,
        engagementLevel: EngagementLevel = .quickTap
    ) -> DiaryEntry {
        DiaryEntry(
            id: UUID(),
            loggedAt: loggedAt,
            playedAt: loggedAt,
            engagementLevel: engagementLevel,
            tags: tags,
            title: nil,
            note: nil,
            progressMs: nil,
            track: track
        )
    }

    // MARK: - Thresholds

    func test_state_belowMinEntries_returnsInsufficientDataWithCountNeeded() {
        let now = Date()
        let entries = [entry(loggedAt: now), entry(loggedAt: now)]
        let backdatedNow = calendar.date(byAdding: .day, value: 4, to: now)!

        let state = RecapCalculator.state(entries: entries, snapshots: [], period: .week, now: backdatedNow, calendar: calendar)

        guard case .insufficientData(let entriesNeeded, _) = state else {
            return XCTFail("expected insufficientData, got \(state)")
        }
        XCTAssertEqual(entriesNeeded, 1)
    }

    func test_state_belowMinElapsedDays_returnsInsufficientDataWithDaysRemaining() {
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)!.start
        let entries = (0..<5).map { _ in entry(loggedAt: weekStart) }

        let state = RecapCalculator.state(entries: entries, snapshots: [], period: .week, now: weekStart, calendar: calendar)

        guard case .insufficientData(_, let daysRemaining) = state else {
            return XCTFail("expected insufficientData, got \(state)")
        }
        XCTAssertGreaterThan(daysRemaining, 0)
    }

    func test_state_enoughEntriesAndElapsedTime_returnsReady() {
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)!.start
        let midWeek = calendar.date(byAdding: .day, value: 4, to: weekStart)!
        let entries = (0..<4).map { entry(loggedAt: calendar.date(byAdding: .hour, value: $0, to: weekStart)!) }

        let state = RecapCalculator.state(entries: entries, snapshots: [], period: .week, now: midWeek, calendar: calendar)

        guard case .ready = state else {
            return XCTFail("expected ready, got \(state)")
        }
    }

    // MARK: - Windows

    func test_currentWindow_matchesCalendarPeriod() {
        let now = Date()
        let window = RecapCalculator.currentWindow(for: .week, now: now, calendar: calendar)
        let expectedStart = calendar.dateInterval(of: .weekOfYear, for: now)!.start

        XCTAssertEqual(window.start, expectedStart)
        XCTAssertEqual(window.end, now)
    }

    func test_priorWindow_isTheFullPreviousPeriod() {
        let now = Date()
        let current = calendar.dateInterval(of: .weekOfYear, for: now)!
        let prior = RecapCalculator.priorWindow(for: .week, now: now, calendar: calendar)

        XCTAssertEqual(prior.end, current.start)
        let expectedDuration = current.end.timeIntervalSince(current.start)
        XCTAssertEqual(prior.end.timeIntervalSince(prior.start), expectedDuration, accuracy: 1)
    }

    // MARK: - Mood card

    func test_state_dominantMoodTag_appearsAsCard() {
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)!.start
        let midWeek = calendar.date(byAdding: .day, value: 4, to: weekStart)!
        let entries = [
            entry(loggedAt: weekStart, tags: [.happy]),
            entry(loggedAt: calendar.date(byAdding: .hour, value: 1, to: weekStart)!, tags: [.happy]),
            entry(loggedAt: calendar.date(byAdding: .hour, value: 2, to: weekStart)!, tags: [.sad]),
        ]

        let state = RecapCalculator.state(entries: entries, snapshots: [], period: .week, now: midWeek, calendar: calendar)

        guard case .ready(let layout) = state else { return XCTFail("expected ready, got \(state)") }
        let allCards = [layout.topWide, layout.narrowLeft, layout.narrowRight, layout.bottomWide].compactMap { $0 }
        let hasMoodCard = allCards.contains { card in
            if case .moodOfPeriod(let tag, let count, _) = card { return tag == .happy && count == 2 }
            return false
        }
        XCTAssertTrue(hasMoodCard, "expected a moodOfPeriod card for .happy, got \(allCards)")
    }

    // MARK: - Logging trend

    func test_state_moreEntriesThanPrior_positiveDeltaPercent() {
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)!.start
        let midWeek = calendar.date(byAdding: .day, value: 4, to: weekStart)!
        let priorWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!

        let currentEntries = (0..<4).map { entry(loggedAt: calendar.date(byAdding: .hour, value: $0, to: weekStart)!) }
        let priorEntries = (0..<2).map { entry(loggedAt: calendar.date(byAdding: .hour, value: $0, to: priorWeekStart)!) }

        let state = RecapCalculator.state(
            entries: currentEntries + priorEntries,
            snapshots: [],
            period: .week,
            now: midWeek,
            calendar: calendar
        )

        guard case .ready(let layout) = state else { return XCTFail("expected ready, got \(state)") }
        let allCards = [layout.topWide, layout.narrowLeft, layout.narrowRight, layout.bottomWide].compactMap { $0 }
        let trendCard = allCards.first { if case .loggingTrend = $0 { return true }; return false }
        guard case .loggingTrend(let count, let deltaPercent) = trendCard else {
            return XCTFail("expected a loggingTrend card, got \(allCards)")
        }
        XCTAssertEqual(count, 4)
        XCTAssertEqual(deltaPercent, 100)
    }

    // MARK: - Top track highlight (no snapshot history)

    func test_state_noSnapshots_fallsBackToTopTrackHighlight() {
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)!.start
        let midWeek = calendar.date(byAdding: .day, value: 4, to: weekStart)!
        let favoriteTrack = track(id: "fav", name: "Favorite Song", artist: "Fave Artist")
        let otherTrack = track(id: "other", name: "Other Song")

        let entries = [
            entry(loggedAt: weekStart, track: favoriteTrack),
            entry(loggedAt: calendar.date(byAdding: .hour, value: 1, to: weekStart)!, track: favoriteTrack),
            entry(loggedAt: calendar.date(byAdding: .hour, value: 2, to: weekStart)!, track: otherTrack),
            entry(loggedAt: calendar.date(byAdding: .hour, value: 3, to: weekStart)!, track: nil),
        ]

        let state = RecapCalculator.state(entries: entries, snapshots: [], period: .week, now: midWeek, calendar: calendar)

        guard case .ready(let layout) = state else { return XCTFail("expected ready, got \(state)") }
        let allCards = [layout.topWide, layout.narrowLeft, layout.narrowRight, layout.bottomWide].compactMap { $0 }
        let hasHighlight = allCards.contains { card in
            if case .topTrackHighlight(let trackName, let artistName, let count) = card {
                return trackName == "Favorite Song" && artistName == "Fave Artist" && count == 2
            }
            return false
        }
        XCTAssertTrue(hasHighlight, "expected topTrackHighlight card, got \(allCards)")
    }

    // MARK: - Rank movement (with snapshot history)

    func test_state_trackClimbedInRank_producesClimbingCard() {
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)!.start
        let midWeek = calendar.date(byAdding: .day, value: 4, to: weekStart)!
        let priorWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!
        let climber = track(id: "climber", name: "Climber")

        let entries = (0..<4).map { entry(loggedAt: calendar.date(byAdding: .hour, value: $0, to: weekStart)!) }

        let priorSnapshot = TasteSnapshot(
            id: UUID(),
            date: priorWeekStart,
            trackEntries: [TasteSnapshotTrackEntry(rank: 5, track: climber)],
            artistEntries: []
        )
        let currentSnapshot = TasteSnapshot(
            id: UUID(),
            date: weekStart,
            trackEntries: [TasteSnapshotTrackEntry(rank: 1, track: climber)],
            artistEntries: []
        )

        let state = RecapCalculator.state(
            entries: entries,
            snapshots: [priorSnapshot, currentSnapshot],
            period: .week,
            now: midWeek,
            calendar: calendar
        )

        guard case .ready(let layout) = state else { return XCTFail("expected ready, got \(state)") }
        let allCards = [layout.topWide, layout.narrowLeft, layout.narrowRight, layout.bottomWide].compactMap { $0 }
        let hasClimb = allCards.contains { card in
            if case .climbing(let kind, let name, let fromRank, let toRank) = card {
                return kind == .track && name == "Climber" && fromRank == 5 && toRank == 1
            }
            return false
        }
        XCTAssertTrue(hasClimb, "expected climbing card, got \(allCards)")
    }

    func test_state_newTrackInSnapshot_producesNewFavoriteCard() {
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)!.start
        let midWeek = calendar.date(byAdding: .day, value: 4, to: weekStart)!
        let priorWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!
        let newTrack = track(id: "new", name: "Brand New")

        let entries = (0..<4).map { entry(loggedAt: calendar.date(byAdding: .hour, value: $0, to: weekStart)!) }

        let priorSnapshot = TasteSnapshot(id: UUID(), date: priorWeekStart, trackEntries: [], artistEntries: [])
        let currentSnapshot = TasteSnapshot(
            id: UUID(),
            date: weekStart,
            trackEntries: [TasteSnapshotTrackEntry(rank: 3, track: newTrack)],
            artistEntries: []
        )

        let state = RecapCalculator.state(
            entries: entries,
            snapshots: [priorSnapshot, currentSnapshot],
            period: .week,
            now: midWeek,
            calendar: calendar
        )

        guard case .ready(let layout) = state else { return XCTFail("expected ready, got \(state)") }
        let allCards = [layout.topWide, layout.narrowLeft, layout.narrowRight, layout.bottomWide].compactMap { $0 }
        let hasNewFavorite = allCards.contains { card in
            if case .newFavorite(let kind, let name, let rank) = card {
                return kind == .track && name == "Brand New" && rank == 3
            }
            return false
        }
        XCTAssertTrue(hasNewFavorite, "expected newFavorite card, got \(allCards)")
    }

    // MARK: - Filler cards

    func test_state_engagementMix_reflectsDetailedRatio() {
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)!.start
        let midWeek = calendar.date(byAdding: .day, value: 4, to: weekStart)!
        let entries = [
            entry(loggedAt: weekStart, engagementLevel: .detailed),
            entry(loggedAt: calendar.date(byAdding: .hour, value: 1, to: weekStart)!, engagementLevel: .quickTap),
            entry(loggedAt: calendar.date(byAdding: .hour, value: 2, to: weekStart)!, engagementLevel: .quickTap),
            entry(loggedAt: calendar.date(byAdding: .hour, value: 3, to: weekStart)!, engagementLevel: .quickTap),
        ]

        let state = RecapCalculator.state(entries: entries, snapshots: [], period: .week, now: midWeek, calendar: calendar)

        guard case .ready(let layout) = state else { return XCTFail("expected ready, got \(state)") }
        let allCards = [layout.topWide, layout.narrowLeft, layout.narrowRight, layout.bottomWide].compactMap { $0 }
        let mixCard = allCards.first { if case .engagementMix = $0 { return true }; return false }
        guard case .engagementMix(let percent) = mixCard else {
            return XCTFail("expected engagementMix card, got \(allCards)")
        }
        XCTAssertEqual(percent, 25)
    }
}
