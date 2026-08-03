//
//  PlaybackProgressAnchor.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 23.07.2026.
//

import Foundation

struct PlaybackProgressAnchor: Equatable {
    let baseProgressMs: Int
    let referenceDate: Date
    let isPlaying: Bool
    let durationMs: Int

    func progressMs(at date: Date) -> Int {
        guard isPlaying else { return baseProgressMs }
        let elapsedMs = Int(date.timeIntervalSince(referenceDate) * 1000)
        return min(durationMs, baseProgressMs + elapsedMs)
    }
}
