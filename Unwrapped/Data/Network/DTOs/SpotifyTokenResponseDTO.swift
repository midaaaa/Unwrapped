//
//  SpotifyTokenResponseDTO.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

struct SpotifyTokenResponseDTO: Decodable {
    let accessToken: String
    let expiresIn: Int
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}
