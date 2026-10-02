//
//  AppLock.swift
//  Pulse
//
//  Created by Marcus Raitner on 02.10.26.
//

import LocalAuthentication
import SwiftUI
import UIKit

/// Prompts Face ID / Touch ID with an automatic device-passcode fallback.
/// Returns `true` if the device has no passcode set at all, since there is
/// nothing to lock with in that case.
func authenticateDeviceOwner() async -> Bool {
    let context = LAContext()
    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else { return true }

    do {
        return try await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: String(localized: "Unlock Pulse to continue"))
    } catch {
        return false
    }
}

/// Shows the lock screen in its own `UIWindow` above all other windows. A SwiftUI
/// overlay on the root view cannot cover sheets or full-screen covers, because
/// those are presented from a layer above the root view's hierarchy.
@MainActor
final class AppLockWindow {
    private var window: UIWindow?

    func setVisible(_ visible: Bool, onUnlock: @escaping () async -> Void) {
        if visible {
            guard window == nil,
                  let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
            else { return }

            let controller = UIHostingController(rootView: AppLockView(onUnlock: onUnlock))
            controller.overrideUserInterfaceStyle = .dark

            let lockWindow = UIWindow(windowScene: scene)
            lockWindow.windowLevel = .alert + 1
            lockWindow.rootViewController = controller
            // Becoming key also resigns the keyboard of any sheet underneath.
            lockWindow.makeKeyAndVisible()
            window = lockWindow
        } else {
            window?.isHidden = true
            window = nil
        }
    }
}
