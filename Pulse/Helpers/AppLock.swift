//
//  AppLock.swift
//  Pulse
//
//  Created by Marcus Raitner on 02.10.26.
//

import LocalAuthentication

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
