//
//  TopArtistDTO.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

nonisolated struct TopArtistDTO: Decodable, Sendable {
    let id: String
    let name: String
    let popularity: Int?
    let images: [SpotifyImageDTO]?
}
