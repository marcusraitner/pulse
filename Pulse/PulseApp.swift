//
//  PulseApp.swift
//  Pulse
//
//  Created by Marcus Raitner on 16.02.26.
//

import SwiftUI
import SwiftData
import OSLog

@main
struct PulseApp: App {
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "PulseApp")
    
    var modelContainer: ModelContainer {
        let schema = Schema([DailyEntry.self])
        let modelconfiguration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )
        
        do {
            return try ModelContainer(for: schema, configurations: modelconfiguration)
        } catch {
            logger.error("ModelContainer initialization failed: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.featureFlags, FeatureFlags(editHistory: false, adminEnabled: true))
            
        }
        .modelContainer(modelContainer)
    }
}
