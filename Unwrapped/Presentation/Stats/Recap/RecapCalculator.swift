//
//  RecapCalculator.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import Foundation

enum RecapCalculator {
    static func currentWindow(for period: RecapPeriod, now: Date = .now, calendar: Calendar = .current) -> RecapWindow {
        let interval = calendar.dateInterval(of: period.calendarComponent, for: now) ?? DateInterval(start: now, end: now)
        return RecapWindow(start: interval.start, end: now)
    }

    static func priorWindow(for period: RecapPeriod, now: Date = .now, calendar: Calendar = .current) -> RecapWindow {
        let currentInterval = calendar.dateInterval(of: period.calendarComponent, for: now) ?? DateInterval(start: now, end: now)
        let priorAnchor = calendar.date(byAdding: period.calendarComponent, value: -1, to: currentInterval.start) ?? currentInterval.start
        let priorInterval = calendar.dateInterval(of: period.calendarComponent, for: priorAnchor) ?? DateInterval(start: priorAnchor, end: priorAnchor)
        return RecapWindow(start: priorInterval.start, end: priorInterval.end)
    }

    static func state(
        entries: [DiaryEntry],
        snapshots: [TasteSnapshot],
        period: RecapPeriod,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> RecapState {
        let current = currentWindow(for: period, now: now, calendar: calendar)
        let prior = priorWindow(for: period, now: now, calendar: calendar)

        let currentEntries = entries.filter { current.contains($0.loggedAt) }
        let elapsedDays = calendar.dateComponents([.day], from: current.start, to: now).day ?? 0

        guard currentEntries.count >= period.minEntries, elapsedDays >= period.minElapsedDays else {
            return .insufficientData(
                entriesNeeded: max(0, period.minEntries - currentEntries.count),
                daysRemaining: max(0, period.minElapsedDays - elapsedDays)
            )
        }

        let priorEntries = entries.filter { prior.contains($0.loggedAt) }

        let mood = moodCard(current: currentEntries, prior: priorEntries)
        let trend = loggingTrendCard(current: currentEntries, prior: priorEntries)

        let currentSnapshot = snapshots.filter { current.contains($0.date) }.max { $0.date < $1.date }
        let priorSnapshot = snapshots.filter { prior.contains($0.date) }.max { $0.date < $1.date }

        var widePool: [RecapCard]
        if let currentSnapshot, let priorSnapshot {
            widePool = rankMovementCards(current: currentSnapshot, prior: priorSnapshot)
        } else if let topTrack = topTrackHighlight(entries: currentEntries) {
            widePool = [topTrack]
        } else {
            widePool = []
        }
        if let mood { widePool.append(mood) }

        var narrowPool: [RecapCard] = [trend]
        narrowPool.append(contentsOf: fillerCards(entries: entries, currentEntries: currentEntries, now: now, calendar: calendar))

        var topWide: RecapCard? = widePool.isEmpty ? nil : widePool.removeFirst()
        var narrowRight: RecapCard? = narrowPool.isEmpty ? nil : narrowPool.removeFirst()
        var narrowLeft: RecapCard? = narrowPool.isEmpty ? nil : narrowPool.removeFirst()
        var bottomWide: RecapCard? = widePool.isEmpty ? nil : widePool.removeFirst()

        if narrowLeft == nil, !widePool.isEmpty { narrowLeft = widePool.removeFirst() }
        if narrowRight == nil, !widePool.isEmpty { narrowRight = widePool.removeFirst() }
        if topWide == nil, !narrowPool.isEmpty { topWide = narrowPool.removeFirst() }
        if bottomWide == nil, !narrowPool.isEmpty { bottomWide = narrowPool.removeFirst() }

        return .ready(RecapCardLayout(topWide: topWide, narrowLeft: narrowLeft, narrowRight: narrowRight, bottomWide: bottomWide))
    }

    // MARK: - Diary-only cards (no snapshot history required)

    private static func moodCard(current: [DiaryEntry], prior: [DiaryEntry]) -> RecapCard? {
        guard let dominant = dominantTag(in: current) else { return nil }
        let count = current.flatMap(\.tags).filter { $0 == dominant }.count
        return .moodOfPeriod(tag: dominant, count: count, isSameAsPrior: dominant == dominantTag(in: prior))
    }

    private static func dominantTag(in entries: [DiaryEntry]) -> MoodTag? {
        let grouped: [MoodTag: Int] = Dictionary(grouping: entries.flatMap(\.tags)) { $0 }
            .mapValues(\.count)
        let sorted: [(tag: MoodTag, count: Int)] = grouped.map { (tag: $0.key, count: $0.value) }.sorted { lhs, rhs in
            guard lhs.count == rhs.count else { return lhs.count > rhs.count }
            return lhs.tag.label < rhs.tag.label
        }
        return sorted.first?.tag
    }

    private static func loggingTrendCard(current: [DiaryEntry], prior: [DiaryEntry]) -> RecapCard {
        guard !prior.isEmpty else {
            return .loggingTrend(count: current.count, deltaPercent: nil)
        }
        let currentCount = Double(current.count)
        let priorCount = Double(prior.count)
        let ratio: Double = (currentCount - priorCount) / priorCount
        let percent: Double = ratio * 100
        let delta = Int(percent.rounded())
        return .loggingTrend(count: current.count, deltaPercent: delta)
    }

    private static func topTrackHighlight(entries: [DiaryEntry]) -> RecapCard? {
        let grouped = Dictionary(grouping: entries.compactMap(\.track)) { $0.id }
        guard let (_, tracks) = grouped.max(by: { $0.value.count < $1.value.count }), let track = tracks.first else { return nil }
        return .topTrackHighlight(trackName: track.name, artistName: track.primaryArtistName, count: tracks.count)
    }

    // MARK: - Filler cards (always computable from the diary alone, used to pad the grid to 2x2)

    private static func fillerCards(entries: [DiaryEntry], currentEntries: [DiaryEntry], now: Date, calendar: Calendar) -> [RecapCard] {
        var cards: [RecapCard] = []
        let streakDays = currentStreak(entries: entries, now: now, calendar: calendar)
        if streakDays > 0 {
            cards.append(.streak(days: streakDays))
        }
        if let activeDay = mostActiveWeekday(entries: currentEntries, calendar: calendar) {
            cards.append(.activeDay(weekday: activeDay.name, count: activeDay.count))
        }
        if let mix = engagementMixPercent(entries: currentEntries) {
            cards.append(.engagementMix(detailedPercent: mix))
        }
        return cards
    }

    private static func currentStreak(entries: [DiaryEntry], now: Date, calendar: Calendar) -> Int {
        let loggedDays = Set(entries.map { calendar.startOfDay(for: $0.loggedAt) })
        var streak = 0
        var day = calendar.startOfDay(for: now)
        while loggedDays.contains(day) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }
        return streak
    }

    private static func mostActiveWeekday(entries: [DiaryEntry], calendar: Calendar) -> (name: String, count: Int)? {
        let grouped: [Int: Int] = Dictionary(grouping: entries) { calendar.component(.weekday, from: $0.loggedAt) }
            .mapValues(\.count)
        let sorted: [(weekday: Int, count: Int)] = grouped.map { (weekday: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        guard let top = sorted.first else { return nil }
        let symbols = calendar.standaloneWeekdaySymbols
        let name = symbols[top.weekday - 1].capitalized(with: Locale.current)
        return (name, top.count)
    }

    private static func engagementMixPercent(entries: [DiaryEntry]) -> Int? {
        guard !entries.isEmpty else { return nil }
        let detailedCount = entries.filter { $0.engagementLevel == .detailed }.count
        let total = Double(entries.count)
        let detailed = Double(detailedCount)
        let ratio: Double = detailed / total
        let percent: Double = ratio * 100
        return Int(percent.rounded())
    }

    // MARK: - Rank-movement cards (need a snapshot in both the current and prior window)

    private static func rankMovementCards(current: TasteSnapshot, prior: TasteSnapshot) -> [RecapCard] {
        var cards: [RecapCard] = []

        let priorTrackRanks = Dictionary(uniqueKeysWithValues: prior.trackEntries.map { ($0.track.id, $0.rank) })
        let priorArtistRanks = Dictionary(uniqueKeysWithValues: prior.artistEntries.map { ($0.artist.id, $0.rank) })

        var bestClimb: RecapCard?
        var bestDelta = 0

        for entry in current.trackEntries {
            guard let priorRank = priorTrackRanks[entry.track.id], priorRank > entry.rank else { continue }
            let delta = priorRank - entry.rank
            if delta > bestDelta {
                bestDelta = delta
                bestClimb = .climbing(kind: .track, name: entry.track.name, fromRank: priorRank, toRank: entry.rank)
            }
        }
        for entry in current.artistEntries {
            guard let priorRank = priorArtistRanks[entry.artist.id], priorRank > entry.rank else { continue }
            let delta = priorRank - entry.rank
            if delta > bestDelta {
                bestDelta = delta
                bestClimb = .climbing(kind: .artist, name: entry.artist.name, fromRank: priorRank, toRank: entry.rank)
            }
        }
        if let bestClimb { cards.append(bestClimb) }

        if let newTrack = current.trackEntries.sorted(by: { $0.rank < $1.rank }).first(where: { priorTrackRanks[$0.track.id] == nil }) {
            cards.append(.newFavorite(kind: .track, name: newTrack.track.name, rank: newTrack.rank))
        } else if let newArtist = current.artistEntries.sorted(by: { $0.rank < $1.rank }).first(where: { priorArtistRanks[$0.artist.id] == nil }) {
            cards.append(.newFavorite(kind: .artist, name: newArtist.artist.name, rank: newArtist.rank))
        }

        return cards
    }
}
