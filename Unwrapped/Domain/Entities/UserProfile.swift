//
//  UserProfile.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import Foundation

enum SubscriptionProduct: String, Sendable {
    case premium, free, open, unknown
}

struct UserProfile: Sendable, Equatable {
    let id: String
    let displayName: String
    let country: String?
    let product: SubscriptionProduct
    let imageURL: URL?
}
