//
//  BackgroundTaskConfig.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import Foundation

enum BackgroundTaskConfig {
    nonisolated static let tasteSnapshotRefreshID = "mida.Unwrapped.tasteSnapshotRefresh"
    nonisolated static let refreshInterval: TimeInterval = 12 * 60 * 60
}
