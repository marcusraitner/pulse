//
//  AppLockPromptGate.swift
//  Pulse
//
//  Created by Marcus Raitner on 09.10.26.
//

import Foundation

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
