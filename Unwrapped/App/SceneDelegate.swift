//
//  SceneDelegate.swift
//  Unwrapped
//
//  Created by Дмитрий Филимонов on 02.08.2026.
//

import UIKit

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let shortcutItem = connectionOptions.shortcutItem else { return }
        ShortcutCoordinator.shared.handle(shortcutType: shortcutItem.type)
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        ShortcutCoordinator.shared.handle(shortcutType: shortcutItem.type)
        completionHandler(true)
    }
}
