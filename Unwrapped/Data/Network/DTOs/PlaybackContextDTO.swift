//
//  PlaybackContextDTO.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

nonisolated struct PlaybackContextDTO: Decodable, Sendable {
    let type: String
    let uri: String
}
