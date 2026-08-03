//
//  DiaryBrowsing.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import SwiftUI

enum DiaryBrowseMode: CaseIterable {
    case entries, tracks, artists

    var label: LocalizedStringKey {
        switch self {
        case .entries: "Entries"
        case .tracks: "Tracks"
        case .artists: "Artists"
        }
    }

    var systemImage: String {
        switch self {
        case .entries: "list.clipboard"
        case .tracks: "music.note"
        case .artists: "person.fill"
        }
    }
}

enum DiarySortField: CaseIterable {
    case date, count, name

    static func availableFields(for mode: DiaryBrowseMode) -> [DiarySortField] {
        mode == .entries ? [.date] : [.date, .count, .name]
    }

    var label: LocalizedStringKey {
        switch self {
        case .date: "Date"
        case .count: "Entry Count"
        case .name: "Name"
        }
    }

    var defaultDirection: DiarySortDirection {
        switch self {
        case .date: .descending
        case .count: .descending
        case .name: .ascending
        }
    }
}

enum DiarySortDirection {
    case ascending, descending

    var toggled: DiarySortDirection { self == .ascending ? .descending : .ascending }

    var systemImage: String { self == .ascending ? "arrow.up" : "arrow.down" }

    func label(for field: DiarySortField) -> LocalizedStringKey {
        switch field {
        case .date: self == .descending ? "Newest First" : "Oldest First"
        case .count: self == .descending ? "Most Logged First" : "Least Logged First"
        case .name: self == .ascending ? "A to Z" : "Z to A"
        }
    }
}
