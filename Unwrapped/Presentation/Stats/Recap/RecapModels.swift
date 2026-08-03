//
//  RecapModels.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import Foundation

enum RecapPeriod: String, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }

    var label: String {
        switch self {
        case .week: String(localized: "This Week")
        case .month: String(localized: "This Month")
        }
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .week: .weekOfYear
        case .month: .month
        }
    }

    var minElapsedDays: Int {
        switch self {
        case .week: 3
        case .month: 10
        }
    }

    var minEntries: Int {
        switch self {
        case .week: 3
        case .month: 5
        }
    }
}

struct RecapWindow: Equatable {
    let start: Date
    let end: Date

    func contains(_ date: Date) -> Bool { date >= start && date < end }
}

enum RecapEntityKind: Equatable {
    case track
    case artist
}

enum RecapCard: Identifiable, Equatable {
    case moodOfPeriod(tag: MoodTag, count: Int, isSameAsPrior: Bool)
    case loggingTrend(count: Int, deltaPercent: Int?)
    case climbing(kind: RecapEntityKind, name: String, fromRank: Int, toRank: Int)
    case newFavorite(kind: RecapEntityKind, name: String, rank: Int)
    case topTrackHighlight(trackName: String, artistName: String, count: Int)
    case streak(days: Int)
    case activeDay(weekday: String, count: Int)
    case engagementMix(detailedPercent: Int)

    var id: String {
        switch self {
        case .moodOfPeriod(let tag, _, _): "mood-\(tag.rawValue)"
        case .loggingTrend: "loggingTrend"
        case .climbing(let kind, let name, _, _): "climbing-\(kind)-\(name)"
        case .newFavorite(let kind, let name, _): "newFavorite-\(kind)-\(name)"
        case .topTrackHighlight(let trackName, _, _): "topTrack-\(trackName)"
        case .streak: "streak"
        case .activeDay(let weekday, _): "activeDay-\(weekday)"
        case .engagementMix: "engagementMix"
        }
    }
}

struct RecapCardLayout: Equatable {
    let topWide: RecapCard?
    let narrowLeft: RecapCard?
    let narrowRight: RecapCard?
    let bottomWide: RecapCard?

    var isEmpty: Bool {
        topWide == nil && narrowLeft == nil && narrowRight == nil && bottomWide == nil
    }
}

enum RecapState: Equatable {
    case insufficientData(entriesNeeded: Int, daysRemaining: Int)
    case ready(RecapCardLayout)
}
