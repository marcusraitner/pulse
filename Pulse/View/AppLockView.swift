//
//  AppLockView.swift
//  Pulse
//
//  Created by Marcus Raitner on 02.10.26.
//

import SwiftUI

/// Full-screen cover shown while the app is locked. Fully opaque so no
/// content underneath is visible, even blurred.
struct AppLockView: View {
    var onUnlock: () async -> Void

    var body: some View {
        ZStack {
            BackgroundImageView()

            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)

                Text("Pulse is locked")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Button("Unlock") {
                    Task { await onUnlock() }
                }
                .buttonStyle(.glassProminent)
                .tint(.accent)
            }
        }
        .task {
            await onUnlock()
        }
    }
}

#Preview {
    AppLockView(onUnlock: {})
}
