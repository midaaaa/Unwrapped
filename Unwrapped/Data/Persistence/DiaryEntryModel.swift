//
//  DiaryEntryModel.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation
import SwiftData

@Model
final class DiaryEntryModel {
    @Attribute(.unique)
    var id: UUID
    var loggedAt: Date
    var playedAt: Date
    var engagementLevel: EngagementLevel
    var tags: [MoodTag]
    var title: String?
    var note: String?
    var progressMs: Int?
    var track: TrackCacheModel?

    init(
        id: UUID = UUID(),
        loggedAt: Date,
        playedAt: Date,
        engagementLevel: EngagementLevel,
        tags: [MoodTag] = [],
        title: String? = nil,
        note: String? = nil,
        progressMs: Int? = nil,
        track: TrackCacheModel? = nil
    ) {
        self.id = id
        self.loggedAt = loggedAt
        self.playedAt = playedAt
        self.engagementLevel = engagementLevel
        self.tags = tags
        self.title = title
        self.note = note
        self.progressMs = progressMs
        self.track = track
    }
}
