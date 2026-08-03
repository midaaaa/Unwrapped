//
//  UserProfileDTO.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

nonisolated struct UserProfileDTO: Decodable, Sendable {
    let id: String
    let displayName: String?
    let country: String?
    let product: String?
    let images: [SpotifyImageDTO]?

    enum CodingKeys: String, CodingKey {
        case id, country, product, images
        case displayName = "display_name"
    }
}
