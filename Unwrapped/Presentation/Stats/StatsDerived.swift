//
//  StatsDerived.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 12.09.2026.
//

import Foundation

struct StatsMoodCount: Identifiable {
    let tag: MoodTag
    let count: Int
    var id: MoodTag { tag }
}

struct StatsActivityBucket: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

struct StatsReplayedTrack {
    let track: Track
    let count: Int
}

struct StatsTopArtistMismatch {
    let spotifyTop: Artist
    let diaryTopName: String
    let diaryTopCount: Int
}

struct StatsEngagementRow: Identifiable {
    let level: EngagementLevel
    let count: Int
    var id: EngagementLevel { level }
}

struct StatsHeatmapCell: Identifiable {
    let weekday: Int
    let hourBlockStart: Int
    let count: Int
    var id: String { "\(weekday)-\(hourBlockStart)" }
}

struct StatsDerived {
    var periodEntries: [DiaryEntry] = []
    var totalEntryCount = 0
    var distinctTrackCount = 0
    var distinctArtistCount = 0
    var moodCounts: [StatsMoodCount] = []
    var moodAxisTickValues: [Int] = [0]
    var activityBucketComponent: Calendar.Component = .day
    var activityBuckets: [StatsActivityBucket] = []
    var currentStreak = 0
    var longestStreak = 0
    var discoveryRate: Double?
    var mostReplayedTrack: StatsReplayedTrack?
    var topArtistMismatch: StatsTopArtistMismatch?
    var engagementMoodBreakdown: [StatsEngagementRow] = []
    var activityHeatmap: [StatsHeatmapCell] = []
    var heatmapMaxCount = 0

    static let empty = StatsDerived()

    func activityBucket(at date: Date?) -> StatsActivityBucket? {
        guard let date else { return nil }
        return activityBuckets.first { $0.date == date }
    }

    func activityBucket(matching tappedDate: Date, calendar: Calendar = .current) -> StatsActivityBucket? {
        activityBuckets.first { bucket in
            guard let bucketEnd = calendar.date(byAdding: activityBucketComponent, value: 1, to: bucket.date) else {
                return false
            }
            return tappedDate >= bucket.date && tappedDate < bucketEnd
        }
    }
}

enum StatsCalculator {
    static let heatmapHourBlockSize = 4

    static func derive(
        entries: [DiaryEntry],
        periodStart: Date?,
        spotifyTopArtist: Artist?,
        calendar: Calendar = .current
    ) -> StatsDerived {
        let periodEntries = periodStart.map { start in entries.filter { $0.loggedAt >= start } } ?? entries
        let periodTracks = periodEntries.compactMap(\.track)
        let periodArtistKeys = periodTracks.flatMap(\.artistGroupingKeys)
        let loggedDates = entries.map(\.loggedAt)

        let moodCounts = moodCounts(in: periodEntries)
        let bucketComponent = activityBucketComponent(for: periodEntries, calendar: calendar)
        let heatmap = activityHeatmap(for: periodEntries, calendar: calendar)

        return StatsDerived(
            periodEntries: periodEntries,
            totalEntryCount: periodEntries.count,
            distinctTrackCount: Set(periodTracks.map(\.id)).count,
            distinctArtistCount: Set(periodArtistKeys.map(\.id)).count,
            moodCounts: moodCounts,
            moodAxisTickValues: axisTickValues(forMax: moodCounts.map(\.count).max() ?? 0),
            activityBucketComponent: bucketComponent,
            activityBuckets: activityBuckets(for: periodEntries, component: bucketComponent, calendar: calendar),
            currentStreak: StreakCalculator.currentStreak(loggedDates: loggedDates, calendar: calendar),
            longestStreak: StreakCalculator.longestStreak(loggedDates: loggedDates, calendar: calendar),
            discoveryRate: discoveryRate(entries: entries, periodArtistKeys: periodArtistKeys, periodStart: periodStart),
            mostReplayedTrack: mostReplayedTrack(in: periodTracks),
            topArtistMismatch: topArtistMismatch(spotifyTop: spotifyTopArtist, periodArtistKeys: periodArtistKeys),
            engagementMoodBreakdown: engagementMoodBreakdown(in: periodEntries),
            activityHeatmap: heatmap,
            heatmapMaxCount: heatmap.map(\.count).max() ?? 0
        )
    }

    // MARK: - Mood

    private static func moodCounts(in periodEntries: [DiaryEntry]) -> [StatsMoodCount] {
        let grouped: [MoodTag: Int] = Dictionary(grouping: periodEntries.flatMap(\.tags)) { $0 }
            .mapValues(\.count)
        let unsorted: [StatsMoodCount] = grouped.map { tag, count in StatsMoodCount(tag: tag, count: count) }
        let sorted: [StatsMoodCount] = unsorted.sorted { lhs, rhs in
            guard lhs.count == rhs.count else { return lhs.count > rhs.count }
            return lhs.tag.label < rhs.tag.label
        }
        return Array(sorted.prefix(8))
    }

    private static func axisTickValues(forMax maxCount: Int) -> [Int] {
        guard maxCount > 0 else { return [0] }
        let rawStep = Double(maxCount) / 4
        let magnitude = pow(10, floor(log10(max(rawStep, 1))))
        let normalized = rawStep / magnitude
        let niceNormalized: Double = normalized <= 1 ? 1 : normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10
        let step = max(1, Int(niceNormalized * magnitude))
        return Array(stride(from: 0, through: maxCount, by: step))
    }

    // MARK: - Activity

    private static func activityBucketComponent(for periodEntries: [DiaryEntry], calendar: Calendar) -> Calendar.Component {
        var earliest: Date?
        var latest: Date?
        for entry in periodEntries {
            if earliest == nil || entry.loggedAt < earliest! { earliest = entry.loggedAt }
            if latest == nil || entry.loggedAt > latest! { latest = entry.loggedAt }
        }
        guard let earliest, let latest else { return .day }

        let spanDays = calendar.dateComponents([.day], from: earliest, to: latest).day ?? 0
        switch spanDays {
        case ..<31: return .day
        case ..<210: return .weekOfYear
        default: return .month
        }
    }

    private static func activityBuckets(
        for periodEntries: [DiaryEntry],
        component: Calendar.Component,
        calendar: Calendar
    ) -> [StatsActivityBucket] {
        let grouped = Dictionary(grouping: periodEntries) { entry in
            calendar.dateInterval(of: component, for: entry.loggedAt)?.start ?? entry.loggedAt
        }
        return grouped
            .map { StatsActivityBucket(date: $0.key, count: $0.value.count) }
            .sorted { $0.date < $1.date }
    }

    private static func activityHeatmap(for periodEntries: [DiaryEntry], calendar: Calendar) -> [StatsHeatmapCell] {
        let blockSize = heatmapHourBlockSize
        var counts: [String: Int] = [:]
        for entry in periodEntries {
            let components = calendar.dateComponents([.weekday, .hour], from: entry.playedAt)
            let blockStart = ((components.hour ?? 0) / blockSize) * blockSize
            counts["\(components.weekday ?? 1)-\(blockStart)", default: 0] += 1
        }
        return (1...7).flatMap { weekday in
            stride(from: 0, to: 24, by: blockSize).map { blockStart in
                StatsHeatmapCell(weekday: weekday, hourBlockStart: blockStart, count: counts["\(weekday)-\(blockStart)"] ?? 0)
            }
        }
    }

    // MARK: - Insights

    private static func discoveryRate(
        entries: [DiaryEntry],
        periodArtistKeys: [(id: String, name: String)],
        periodStart: Date?
    ) -> Double? {
        let periodArtistIds = Set(periodArtistKeys.map(\.id))
        guard !periodArtistIds.isEmpty else { return nil }

        var firstAppearance: [String: Date] = [:]
        for entry in entries {
            guard let track = entry.track else { continue }
            for key in track.artistGroupingKeys {
                if let existing = firstAppearance[key.id] {
                    firstAppearance[key.id] = min(existing, entry.loggedAt)
                } else {
                    firstAppearance[key.id] = entry.loggedAt
                }
            }
        }

        let windowStart = periodStart ?? .distantPast
        let newCount = periodArtistIds.filter { (firstAppearance[$0] ?? .distantPast) >= windowStart }.count
        return Double(newCount) / Double(periodArtistIds.count)
    }

    private static func mostReplayedTrack(in periodTracks: [Track]) -> StatsReplayedTrack? {
        let grouped = Dictionary(grouping: periodTracks) { $0.id }
        let sorted = grouped.values.sorted { lhs, rhs in
            guard lhs.count == rhs.count else { return lhs.count > rhs.count }
            return (lhs.first?.name ?? "") < (rhs.first?.name ?? "")
        }
        guard let topGroup = sorted.first, topGroup.count > 1, let track = topGroup.first else { return nil }
        return StatsReplayedTrack(track: track, count: topGroup.count)
    }

    private static func topArtistMismatch(
        spotifyTop: Artist?,
        periodArtistKeys: [(id: String, name: String)]
    ) -> StatsTopArtistMismatch? {
        guard let spotifyTop else { return nil }

        let diaryCounts = Dictionary(grouping: periodArtistKeys) { $0.id }.mapValues(\.count)
        let sorted = diaryCounts.sorted { lhs, rhs in
            guard lhs.value == rhs.value else { return lhs.value > rhs.value }
            return lhs.key < rhs.key
        }
        guard let top = sorted.first,
              top.key != spotifyTop.id,
              let diaryTopName = periodArtistKeys.first(where: { $0.id == top.key })?.name
        else { return nil }

        return StatsTopArtistMismatch(spotifyTop: spotifyTop, diaryTopName: diaryTopName, diaryTopCount: top.value)
    }

    private static func engagementMoodBreakdown(in periodEntries: [DiaryEntry]) -> [StatsEngagementRow] {
        var counts: [EngagementLevel: Int] = [:]
        for entry in periodEntries {
            counts[entry.engagementLevel, default: 0] += 1
        }
        return EngagementLevel.allCases.compactMap { level in
            guard let count = counts[level] else { return nil }
            return StatsEngagementRow(level: level, count: count)
        }
    }
}
