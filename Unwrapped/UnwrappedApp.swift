//
//  UnwrappedApp.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 22.07.2026.
//

import SwiftUI

@main
struct UnwrappedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
        .backgroundTask(.appRefresh(BackgroundTaskConfig.tasteSnapshotRefreshID)) {
            await container.performTasteSnapshotRefresh()
            await container.scheduleTasteSnapshotRefresh()
        }
    }
}
