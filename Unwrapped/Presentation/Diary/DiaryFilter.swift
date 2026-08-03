//
//  DiaryFilter.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import Foundation

struct DiaryFilter: Equatable {
    var kinds: Set<EngagementLevel> = [.quickTap, .detailed]
    var moodTags: Set<MoodTag> = []
    var dateRange: ClosedRange<Date>?

    var isActive: Bool {
        kinds != [.quickTap, .detailed] || !moodTags.isEmpty || dateRange != nil
    }

    func matches(_ entry: DiaryEntry) -> Bool {
        guard kinds.contains(entry.engagementLevel) else { return false }
        if !moodTags.isEmpty, moodTags.isDisjoint(with: entry.tags) { return false }
        if let dateRange, !dateRange.contains(entry.loggedAt) { return false }
        return true
    }
}
