//
//  ShortcutCoordinator.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import Foundation

nonisolated enum ShortcutType {
    static let logCurrentTrack = "LogCurrentTrack"
}

@MainActor
@Observable
final class ShortcutCoordinator {
    static let shared = ShortcutCoordinator()

    var isShowingLogCurrentTrack = false

    private init() {}

    nonisolated func handle(shortcutType: String) {
        guard shortcutType == ShortcutType.logCurrentTrack else { return }
        Task { @MainActor in
            ShortcutCoordinator.shared.isShowingLogCurrentTrack = true
        }
    }
}
