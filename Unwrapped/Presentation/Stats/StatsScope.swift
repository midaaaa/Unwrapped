//
//  StatsScope.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 30.07.2026.
//

import Foundation

enum StatsScope: Identifiable, Hashable {
    case track(id: String, name: String)
    case artist(id: String, name: String)

    var id: String {
        switch self {
        case .track(let id, _): "track:\(id)"
        case .artist(let id, _): "artist:\(id)"
        }
    }

    var name: String {
        switch self {
        case .track(_, let name): name
        case .artist(_, let name): name
        }
    }

    func entries(in viewModel: StatsViewModel) -> [DiaryEntry] {
        switch self {
        case .track(let id, _): viewModel.entries(forTrackID: id)
        case .artist(let id, _): viewModel.entries(forArtistID: id)
        }
    }
}
