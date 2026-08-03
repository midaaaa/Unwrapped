//
//  MoodTag.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation

enum MoodTag: String, Sendable, Codable, CaseIterable {
    case happy
    case sad
    case energetic
    case calm
    case nostalgic
    case focused
    case melancholic
    case euphoric
    case anxious
    case angry
    case romantic
    case hopeful
    case lonely
    case confident
    case dreamy
    case rebellious
    case grateful
    case bittersweet
    case triumphant
    case relaxed
    case restless
    case heartbroken
    case playful
    case reflective
    case motivated
    case peaceful

    var emoji: String {
        switch self {
        case .happy: "😊"
        case .sad: "😢"
        case .energetic: "⚡️"
        case .calm: "😌"
        case .nostalgic: "🕰️"
        case .focused: "🎯"
        case .melancholic: "🌧️"
        case .euphoric: "🤩"
        case .anxious: "😰"
        case .angry: "😠"
        case .romantic: "💕"
        case .hopeful: "🌅"
        case .lonely: "🌑"
        case .confident: "💪"
        case .dreamy: "☁️"
        case .rebellious: "🔥"
        case .grateful: "🙏"
        case .bittersweet: "🍂"
        case .triumphant: "🏆"
        case .relaxed: "🧘"
        case .restless: "🌀"
        case .heartbroken: "💔"
        case .playful: "🎈"
        case .reflective: "🪞"
        case .motivated: "🚀"
        case .peaceful: "🕊️"
        }
    }

    var label: String {
        switch self {
        case .happy: String(localized: "Happy")
        case .sad: String(localized: "Sad")
        case .energetic: String(localized: "Energetic")
        case .calm: String(localized: "Calm")
        case .nostalgic: String(localized: "Nostalgic")
        case .focused: String(localized: "Focused")
        case .melancholic: String(localized: "Melancholic")
        case .euphoric: String(localized: "Euphoric")
        case .anxious: String(localized: "Anxious")
        case .angry: String(localized: "Angry")
        case .romantic: String(localized: "Romantic")
        case .hopeful: String(localized: "Hopeful")
        case .lonely: String(localized: "Lonely")
        case .confident: String(localized: "Confident")
        case .dreamy: String(localized: "Dreamy")
        case .rebellious: String(localized: "Rebellious")
        case .grateful: String(localized: "Grateful")
        case .bittersweet: String(localized: "Bittersweet")
        case .triumphant: String(localized: "Triumphant")
        case .relaxed: String(localized: "Relaxed")
        case .restless: String(localized: "Restless")
        case .heartbroken: String(localized: "Heartbroken")
        case .playful: String(localized: "Playful")
        case .reflective: String(localized: "Reflective")
        case .motivated: String(localized: "Motivated")
        case .peaceful: String(localized: "Peaceful")
        }
    }
}
