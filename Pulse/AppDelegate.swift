//
//  AppDelegate.swift
//  Pulse
//
//  Created by Marcus Raitner on 09.10.26.
//

import SwiftUI
import UserNotifications

/// UIApplicationDelegate that sets this class as the `UNUserNotificationCenter` delegate
/// so notification tap actions can open deep-link URLs while the app is foregrounded.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard
            let urlString = response.notification.request.content.userInfo["url"] as? String,
            let url = URL(string: urlString)
        else { return }
        await UIApplication.shared.open(url)
    }
}
