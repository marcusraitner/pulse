//
//  ContentView.swift
//  collins score
//
//  Created by Marcus Raitner on 20.04.25.
//

import OSLog
import SwiftData
import SwiftUI
import StoreKit

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.featureFlags) private var featureFlags
    @Environment(\.requestReview) private var requestReview
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("freezeHistory") private var freezeHistory: Bool = true
    @AppStorage("showStats") private var showStats: Bool = true
    
    @State private var selectedEntry: DailyEntry = DailyEntry(date: .now)
    @State private var today: DailyEntry = DailyEntry(date: .now)
    @State private var isPresentingSettings: Bool = false
    @State private var isPresentingAbout: Bool = false
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "ContentView")

    private var countDays: Int {
        var descriptor = FetchDescriptor<DailyEntry>(predicate: #Predicate { _ in true })
        descriptor.includePendingChanges = true
        return (try? context.fetchCount(descriptor)) ?? 0
    }
    
    private var countLog: Int {
        var descriptor = FetchDescriptor<DailyLogEntry>(predicate: #Predicate { _ in true })
        descriptor.includePendingChanges = true
        return (try? context.fetchCount(descriptor)) ?? 0
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                dateView
                
                TimeLineView(selectedEntry: $selectedEntry)
                    .padding(.vertical)
                    .padding(.bottom, 10)
                
                LogEntriesView(day: selectedEntry)
            }
            .navigationBarTitleDisplayMode(.inline)
            .background {
                GeometryReader { geo in
                    Image(colorScheme == .dark ? "mountain-dark" : "mountain")
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .brightness(colorScheme == .dark ? 0.0 : -0.1)
                        .ignoresSafeArea(.all)
                }
            }
            .ignoresSafeArea(.keyboard)
            .sheet(isPresented: $isPresentingAbout) {
                aboutSheetStack
            }
            .sheet(
                isPresented: $isPresentingSettings,
                onDismiss: setNotifications
            ) {
                settingsSheetStack
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape.fill") {
                        isPresentingSettings = true
                    }
                    .tint(.white)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("About", systemImage: "line.3.horizontal") {
                        isPresentingAbout = true
                    }
                    .tint(.white)
                }
                ToolbarItem(placement: .principal) {
                    if showStats {
                        HStack {
                            Text("\(countDays)")
                            Image(systemName: "calendar")
                            Text("\(countLog)")
                                .padding(.leading, 4)
                            Image(systemName: "list.bullet.rectangle")
                        }
                        .fontWeight(.light)
                        .foregroundStyle(.white)
                    }
                }
                if featureFlags.adminEnabled {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Delete Entry", systemImage: "trash") {
                            context.delete(selectedEntry)
                            try? context.save()
                        }
                        .tint(.white)
                    }
                }
            }
            .task {
                await initApplication()
            }
        }
        .onChange(of: countLog) { old, new in
            if new > old && (new == 3 || new == 20 || new == 50 || new == 100) {
                    presentReview()
            }
        }
#if DEBUG
        // Expose an accessibility identifier
        .accessibilityIdentifier("dateView")
        // and a values containing the selectedEntry for UI Tests
        .accessibilityValue(
            Text("selectedEntry:\(DateFormatHelper.formatDate(selectedEntry.date))")
        )
#endif  // DEBUG only for UI Tests
    }

    private func initApplication() async {

        #if DEBUG
            let args = ProcessInfo.processInfo.arguments

            if args.contains("--disable-animations") {
                UIView.setAnimationsEnabled(false)
            }
        #endif  // DEBUG only for testing

        if !featureFlags.editHistory {
            // make sure, that history is frozen if feature is disabled
            freezeHistory = true
        }
        
        // Request authorization for notifications
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound])
        } catch {
            logger.error("Error NotificationCenter: \(error.localizedDescription)")
        }
    }

    private func setNotifications() {
        // Remove all pending notifications
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()

        // Set new notifications based on user's choice
        if notificationsEnabled {
            let defaults = UserDefaults.standard
            let notificationTimes =
                defaults.value(forKey: "notificationTimes") as? [Date] ?? []

            for time in notificationTimes {
                let content = UNMutableNotificationContent()
                content.title = String(localized: "What's going on?")
                content.body = String(
                    localized: "It's time to log your activities and feelings!"
                )
                content.sound = .default

                let components = Calendar.current.dateComponents(
                    [.hour, .minute],
                    from: time
                )
                let dateTrigger = UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: true
                )
                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: dateTrigger
                )

                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    private func presentReview() {
        Task {
            // Delay for two seconds to avoid interrupting the person using the app.
            try await Task.sleep(for: .seconds(2))
            requestReview()
        }
    }
    
    private var dateView: some View {
        HStack {
            VStack(alignment: .center) {
                Text(selectedEntry.date.formatted(.dateTime.weekday(.wide)))
                Text(
                    selectedEntry.date.formatted(
                        .dateTime.day().month(.wide).year()
                    )
                )
            }
            .font(.system(.title, design: .serif).bold())
            .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.vertical)
    }
    
    private var aboutSheetStack: some View {
        NavigationStack {
            AboutView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        if #available(iOS 26, *) {
                            Button(role: .confirm) {
                                isPresentingAbout = false
                            }
                        } else {
                            Button("Close") {
                                isPresentingAbout = false
                            }
                        }
                    }
                }
        }
    }
    
    private var settingsSheetStack: some View {
        NavigationStack {
            SettingsView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        if #available(iOS 26, *) {
                            Button(role: .confirm) {
                                isPresentingSettings = false
                            }
                        } else {
                            Button("Close") {
                                isPresentingSettings = false
                            }
                        }
                    }
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}
