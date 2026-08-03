//
//  Artist.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

struct Artist: Sendable, Equatable, Identifiable {
    let id: String
    let name: String
    let genres: [String]
    let popularity: Int
    let imageURL: URL?
}
