//
//  SpotifyImageDTO.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

nonisolated struct SpotifyImageDTO: Decodable, Sendable {
    let url: String
    let height: Int?
    let width: Int?
}
