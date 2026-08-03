//
//  TimelineActiveEntryResolver.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 26.07.2026.
//

import Foundation

enum TimelineActiveEntryResolver {
    static func sorted(_ entries: [DiaryEntry]) -> [DiaryEntry] {
        entries.sorted { lhs, rhs in
            let lhsProgress = lhs.progressMs ?? 0
            let rhsProgress = rhs.progressMs ?? 0
            if lhsProgress != rhsProgress { return lhsProgress < rhsProgress }
            return lhs.loggedAt < rhs.loggedAt
        }
    }

    static func activeEntryID(
        in sortedEntries: [DiaryEntry],
        atProgressMs progressMs: Int,
        windowMs: Int
    ) -> DiaryEntry.ID? {
        activeEntry(in: sortedEntries, atProgressMs: progressMs, windowMs: windowMs)?.id
    }

    static func activeEntry(
        in sortedEntries: [DiaryEntry],
        atProgressMs progressMs: Int,
        windowMs: Int
    ) -> (id: DiaryEntry.ID, remainingMs: Int)? {
        var windowEnd = Int.min
        var previousEntryProgress: Int?
        for entry in sortedEntries {
            let entryProgress = entry.progressMs ?? 0
            if entryProgress == previousEntryProgress { continue }
            previousEntryProgress = entryProgress

            guard entryProgress >= windowEnd else { continue }

            let displayEnd = entryProgress + windowMs
            if progressMs >= entryProgress && progressMs < displayEnd {
                return (entry.id, displayEnd - progressMs)
            }
            windowEnd = displayEnd
        }
        return nil
    }
}
