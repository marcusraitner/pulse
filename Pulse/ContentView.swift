//
//  ContentView.swift
//  collins score
//
//  Created by Marcus Raitner on 20.04.25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Query(sort: \DailyEntry.date) private var allEntries: [DailyEntry]
    
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.featureFlags) private var featureFlags
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("freezeHistory") private var freezeHistory: Bool = true
    
    @State private var selectedEntry: DailyEntry = DailyEntry(date: .now)
    @State private var isPresentingSettings: Bool = false
    @State private var isPresentingAbout: Bool = false
    
#if DEBUG
    @State private var testRemovedToday: Bool = false
#endif // DEBUG only for UI Tests
    
    private var today: DailyEntry {
        // create today's entry if missing
        updateToday()
        // allEntries now contains at least today's entry
        return allEntries.last!
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                dateView
                
                
                TimeLineView(allEntries: allEntries, selectedEntry: $selectedEntry)
                    .padding(.vertical)
                    .padding(.bottom, 10)
                
                LogEntriesView(day: selectedEntry)
            }
            .ignoresSafeArea(.keyboard)
            .background {
                // for some reason, the GeometryReader is needed to prevent image from moving up when keyboard is shown
                GeometryReader { geo in
                    Image(colorScheme == .dark ? "mountain-dark" : "mountain")
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .brightness(colorScheme == .dark ? 0.0 : -0.1)
                }
                .ignoresSafeArea(.all)
            }
            .sheet(isPresented: $isPresentingAbout) {
                NavigationStack {
                    AboutView()
                        .toolbar {
                            ToolbarItem (placement: .topBarLeading) {
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
            .sheet(isPresented: $isPresentingSettings, onDismiss: setNotifications) {
                NavigationStack {
                    SettingsView()
                        .toolbar {
                            ToolbarItem (placement: .confirmationAction) {
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape.fill") {
                        isPresentingSettings = true
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("About", systemImage: "line.3.horizontal") {
                        isPresentingAbout = true
                    }
                }
                if featureFlags.enableRemovingEntries {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Delete", systemImage: "trash") {
                            context.delete(selectedEntry)
                            try? context.save()
                        }
                    }
                }
            }
            .task {
                await initApplication()
            }
            .onChange(of: allEntries, initial: true) {
                // allEntries changes when a new day is added; let's scroll to it
                selectedEntry = today
            }
            .onChange(of: scenePhase) { _, newPhase in
#if DEBUG
                let args = ProcessInfo.processInfo.arguments

                if args.contains("--remove-today-on-inactive") {
                    if newPhase == .inactive && !testRemovedToday {
                        testRemovedToday = true
                        if let today = allEntries.last {
                            context.delete(today)
                            try? context.save()
                        }
                    }
                }
#endif // DEBUG: Only for testing
            }
        }
#if DEBUG
        // Expose an accessibility identifier
        .accessibilityIdentifier("dateView")
        // and a values containing the selectedEntry for UI Tests
        .accessibilityValue(Text("selectedEntry:\(formatDate(selectedEntry.date))"))
#endif // DEBUG only for UI Tests
    }
    
    private func initApplication() async {
        
#if DEBUG
        let args = ProcessInfo.processInfo.arguments

        if args.contains("--disable-animations") {
            UIView.setAnimationsEnabled(false)
        }
#endif // DEBUG only for testing

        if !featureFlags.editHistory {
            // make sure, that history is frozen if feature is disabled
            freezeHistory = true
        }
        
        // Request authorization for notifications
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func setNotifications() {
        // Remove all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Set new notifications based on user's choice
        if notificationsEnabled {
            let defaults = UserDefaults.standard
            let notificationTimes = defaults.value(forKey: "notificationTimes") as? [Date] ?? []
            
            for time in notificationTimes {
                let content = UNMutableNotificationContent()
                content.title = String(localized: "What's going on?")
                content.body = String(localized: "It's time to log your activities and feelings!")
                content.sound = .default
                
                let components = Calendar.current.dateComponents([.hour, .minute], from: time)
                let dateTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: dateTrigger)
                
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    private func updateToday() {
        if let entry = allEntries.last {
            if Calendar.current.isDateInToday(entry.date) {
                return
            }
        }
        
        // entry for today missing: create and save it
        let today = DailyEntry(date: .now)
        context.insert(today)
        try? context.save()
    }
    
#if DEBUG
    private func formatDate(_ date: Date) -> String {
        let RFC3339DateFormatter = DateFormatter()
        RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return RFC3339DateFormatter.string(from: date)
    }
#endif // DEBUG Only for testing
    
    private var dateView: some View {
        HStack {
            VStack(alignment: .center) {
                Text(
                    selectedEntry.date.formatted(
                        .dateTime.day().month().year().weekday(.wide)
                    )
                )
            }
            .font(.system(.title, design: .serif).bold())
            .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.vertical)
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}
