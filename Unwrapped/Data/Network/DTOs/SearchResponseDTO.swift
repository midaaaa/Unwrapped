//
//  SearchResponseDTO.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

nonisolated struct SearchTracksResponseDTO: Decodable, Sendable {
    struct TracksPageDTO: Decodable, Sendable {
        let items: [TrackDTO]
        let total: Int
        let limit: Int
        let offset: Int
    }

    let tracks: TracksPageDTO
}
