//
//  DiaryEntry.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation

struct DiaryEntry: Sendable, Equatable, Identifiable {
    let id: UUID
    let loggedAt: Date
    let playedAt: Date
    let engagementLevel: EngagementLevel
    let tags: [MoodTag]
    let title: String?
    let note: String?
    let progressMs: Int?
    let track: Track?

    var titleOrNoteHeading: String? {
        if let title, !title.isEmpty { return title }
        if let note, let firstLine = note.split(separator: "\n", maxSplits: 1).first {
            return String(firstLine)
        }
        return nil
    }
}
