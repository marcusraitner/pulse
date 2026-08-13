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
    
    let modelContainer: ModelContainer
    
    init() {
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
            ContentView()
                .environment(\.featureFlags, FeatureFlags(adminEnabled: false))
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
    }
}

/// UIApplicationDelegate that sets this class as the `UNUserNotificationCenter` delegate
/// so notification tap actions can open deep-link URLs while the app is foregrounded.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard
            let urlString = response.notification.request.content.userInfo["url"] as? String,
            let url = URL(string: urlString)
        else { return }
        await UIApplication.shared.open(url)
    }
}
