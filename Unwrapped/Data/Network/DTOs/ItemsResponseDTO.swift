//
//  ItemsResponseDTO.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

nonisolated struct ItemsResponseDTO<Item: Decodable & Sendable>: Decodable, Sendable {
    let items: [Item]
}
