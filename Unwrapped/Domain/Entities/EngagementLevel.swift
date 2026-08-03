//
//  EngagementLevel.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation

enum EngagementLevel: String, Sendable, Codable, CaseIterable {
    case detailed, quickTap

    var systemImage: String {
        switch self {
        case .quickTap: "sparkles"
        case .detailed: "text.bubble"
        }
    }

    var label: String {
        switch self {
        case .quickTap: String(localized: "Quick Reaction")
        case .detailed: String(localized: "Detailed Entry")
        }
    }
}
