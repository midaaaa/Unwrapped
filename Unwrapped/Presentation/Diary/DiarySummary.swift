//
//  DiarySummary.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import Foundation

protocol DiarySummary: Identifiable where ID == String {
    var entryCount: Int { get }
    var lastLoggedAt: Date { get }
    var sortName: String { get }
}

struct DiaryTrackSummary: DiarySummary {
    let track: Track
    let entries: [DiaryEntry]

    var id: String { track.id }
    var entryCount: Int { entries.count }
    var lastLoggedAt: Date { entries.map(\.loggedAt).max() ?? .distantPast }
    var sortName: String { track.name }
}

struct DiaryArtistSummary: DiarySummary {
    let artistId: String
    let artistName: String
    let entries: [DiaryEntry]
    var fetchedImageURL: URL?

    var id: String { artistId }
    var entryCount: Int { entries.count }
    var trackCount: Int { Set(entries.compactMap { $0.track?.id }).count }
    var lastLoggedAt: Date { entries.map(\.loggedAt).max() ?? .distantPast }
    var sortName: String { artistName }
    var hasResolvableArtistId: Bool { entries.contains { $0.track?.artistIds.contains(artistId) == true } }
    var imageURL: URL? {
        entries.lazy.compactMap { $0.track?.imageURL(forArtistId: artistId) }.first ?? fetchedImageURL
    }
}
