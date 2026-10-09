//
//  PulseApp.swift
//  Pulse
//
//  Created by Marcus Raitner on 16.02.26.
//

import SwiftUI
import SwiftData
import OSLog

/// App entry point. Sets up the SwiftData `ModelContainer` with CloudKit sync
/// and the versioned migration plan, then injects `FeatureFlags` into the environment.
@main
struct PulseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "PulseApp")
    @State private var filterState = FilterState()
    @State private var syncMonitor: ICloudSyncMonitor
    
    let modelContainer: ModelContainer
    
    init() {
        // observe CloudKit before the container exists, so its setup and first import are seen
        let syncMonitor = ICloudSyncMonitor()
        syncMonitor.start()
        _syncMonitor = State(initialValue: syncMonitor)

        let schema = Schema([DailyEntry.self, DailyLogEntry.self, DailyKPIValue.self, KPITemplate.self, Tag.self])
        let modelconfiguration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )
        
        do {
            modelContainer =  try ModelContainer(
                for: schema,
                migrationPlan: PulseMigrationPlan.self,
                configurations: modelconfiguration
            )
        } catch {
            logger.error("ModelContainer initialization failed: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.featureFlags, FeatureFlags(adminEnabled: false))
                .environment(filterState)
                .environment(syncMonitor)
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
    }
}
