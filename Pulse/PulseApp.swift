//
//  PulseApp.swift
//  Pulse
//
//  Created by Marcus Raitner on 16.02.26.
//

import SwiftUI
import SwiftData

@main
struct PulseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.featureFlags, FeatureFlags(editHistory: false))
        }
        .modelContainer(for: DailyEntry.self)
    }
}
