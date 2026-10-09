//
//  RootView.swift
//  Pulse
//
//  Created by Marcus Raitner on 09.10.26.
//

import SwiftUI

/// Wraps `ContentView` with the optional Face ID / Touch ID app lock, shown in a
/// separate window so it also covers sheets. Locks
/// whenever the scene leaves `.active` and re-authenticates on return.
struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppStorageKeys.appLockEnabled) private var appLockEnabled: Bool = false
    @State private var isUnlocked = false
    @State private var lockWindow = AppLockWindow()
    @State private var promptGate = AppLockPromptGate()

    var body: some View {
        ContentView()
            .onChange(of: appLockEnabled && !isUnlocked, initial: true) { _, isLocked in
                lockWindow.setVisible(isLocked, onUnlock: { await unlock() })
            }
            .onChange(of: scenePhase, initial: true) { _, newPhase in
                guard appLockEnabled else {
                    isUnlocked = true
                    return
                }

                switch newPhase {
                case .active:
                    if !isUnlocked { Task { await unlock(automatic: true) } }
                case .background:
                    isUnlocked = false
                    promptGate.reset()
                default:
                    break
                }
            }
    }

    /// `automatic` is the prompt on returning to the app; otherwise the user tapped Unlock.
    private func unlock(automatic: Bool = false) async {
        guard automatic ? promptGate.beginAutomatic() : promptGate.beginManual() else { return }
        isUnlocked = await authenticateDeviceOwner()
        promptGate.finish()
    }
}
