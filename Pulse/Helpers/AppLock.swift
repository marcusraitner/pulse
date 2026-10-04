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

/// Decides when the lock screen may start the system Face ID / passcode prompt.
///
/// The prompt itself moves the scene to `.inactive` and back to `.active`, so starting a
/// prompt on every `.active` would re-prompt after each failure or cancel, in a loop that
/// burns the system's failed-attempt allowance. Instead: at most one automatic prompt per
/// lock session, never two evaluations at once, and the Unlock button as the way to retry.
struct AppLockPromptGate {
    private var hasAutoPrompted = false
    private var isAuthenticating = false

    /// The scene became active while locked. `true` at most once per lock session.
    mutating func beginAutomatic() -> Bool {
        guard !hasAutoPrompted, !isAuthenticating else { return false }
        hasAutoPrompted = true
        isAuthenticating = true
        return true
    }

    /// The user tapped Unlock. Always allowed unless a prompt is already showing.
    mutating func beginManual() -> Bool {
        guard !isAuthenticating else { return false }
        isAuthenticating = true
        return true
    }

    /// The prompt finished, successfully or not.
    mutating func finish() {
        isAuthenticating = false
    }

    /// A new lock session starts (the app went to the background).
    mutating func reset() {
        hasAutoPrompted = false
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
