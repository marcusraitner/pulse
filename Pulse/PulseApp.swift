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
        }
        .modelContainer(for: DailyEntry.self)
    }
}
