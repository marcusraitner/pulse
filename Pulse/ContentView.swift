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
    @State private var needToScroll: Bool = true
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
                
                TimeLineView(allEntries: allEntries, selectedEntry: $selectedEntry, needToScroll: $needToScroll)
                    .padding(.vertical)
                    .padding(.bottom, 10)
                
                LogEntriesView(day: selectedEntry)
            }
            .ignoresSafeArea(.keyboard)
            .background {
                imageBackground
            }
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
            .onChange(of: allEntries, initial: true) {
                // allEntries changes when a new day is added; let's scroll to it
                selectedEntry = today
                needToScroll = true
            }
            .onChange(of: scenePhase) { _, newPhase in
                #if DEBUG
                removeTodayOnInactive(newPhase: newPhase)
                #endif  // DEBUG: Only for testing
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

    private func removeTodayOnInactive(newPhase: ScenePhase) {
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
            print(error.localizedDescription)
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

    private func closestFilteredEntry(
        in all: [DailyEntry],
        to target: DailyEntry,
        where predicate: (DailyEntry) -> Bool,
        preferLowerIndexOnTie: Bool = true) -> DailyEntry? {
            
        guard let targetIndex = all.firstIndex(of: target) else { return nil }
        if predicate(target) { return target }

        var offset = 1
        while targetIndex - offset >= 0 || targetIndex + offset < all.count {
            let leftIndex = targetIndex - offset
            let rightIndex = targetIndex + offset

            // Check left first or right first depending on tie preference
            if preferLowerIndexOnTie {
                if leftIndex >= 0, predicate(all[leftIndex]) { return all[leftIndex] }
                if rightIndex < all.count, predicate(all[rightIndex]) { return all[rightIndex] }
            } else {
                if rightIndex < all.count, predicate(all[rightIndex]) { return all[rightIndex] }
                if leftIndex >= 0, predicate(all[leftIndex]) { return all[leftIndex] }
            }

            offset += 1
        }

        return nil
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
    
    private var imageBackground: some View {
        Image(colorScheme == .dark ? "mountain-dark" : "mountain")
            .resizable()
            .scaledToFill()
            .frame(minWidth: 0, maxWidth: .infinity)
            .brightness(colorScheme == .dark ? 0.0 : -0.1)
            .ignoresSafeArea(.all)
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}
