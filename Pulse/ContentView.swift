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
    @Environment(\.featureFlags) private var featureFlags
    @Environment(\.requestReview) private var requestReview
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("freezeHistory") private var freezeHistory: Bool = true
    @AppStorage("showStats") private var showStats: Bool = true
    @AppStorage("reflectionReminder") private var reflectionReminder: Bool = true
    @AppStorage("reflectionReminderTime") private var reflectionReminderTime: Date?
    @AppStorage("theme") private var theme: String = "default"
    
    @State private var reviewService = ReviewService()
    @State private var selectedEntry: DailyEntry = DailyEntry(date: .now)
    @State private var triggerScrollToToday: Bool = false
    @State private var isPresentingSettings: Bool = false
    @State private var isPresentingNewEntry: Bool = false
    @State private var isPresentingEditEntry: Bool = false
    @State private var editingLogEntry = DailyLogEntry(timestamp: .now, log: "", score: 0)
    @State private var isPresentingReflection: Bool = false
    @State private var refreshView: Bool = false
    
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
            ZStack(alignment: .bottomTrailing) {

                BackgroundImageView()

                ScrollView {
                    LazyVStack {
                        // The currently selected date
                        SelectedDateView(date: selectedEntry.date)
                            .padding(.horizontal)
                            .background(alignment: .bottom) {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundStyle(.white)
                            }
                        
                        // Delete Button (only admin mode)
                        if featureFlags.adminEnabled {
                            Button("Delete Entry", systemImage: "trash") {
                                context.delete(selectedEntry)
                                do {
                                    try context.save()
                                } catch {
                                    logger.error("Failed saving deleted entry: \(String(describing: error))")
                                }
                            }
                            .tint(.white)
                        }
                        
                        // The timeline scroll view
                        HorizontalTimelineView(selectedEntry: $selectedEntry, scrollToToday: $triggerScrollToToday)
                            .padding(.vertical)
                        
                        // The daily reflection
                        DailyReflectionCard(summary: selectedEntry.summary) {
                            isPresentingReflection = true
                        }

                        // The log entries for this day
                        LogEntriesView(day: selectedEntry) { entry in
                            editingLogEntry = entry
                            isPresentingEditEntry = true
                        }
                        .padding(.horizontal, 5)
                    }
                }
                .ignoresSafeArea(.all, edges: .bottom)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $isPresentingSettings,
                    onDismiss: setNotifications) {
                    settingsSheetStack
                }
                .sheet(isPresented: $isPresentingNewEntry) {
                    NavigationStack {
                        LogEntrySheet() { editedEntry in

                            if selectedEntry.logEntries == nil {
                                selectedEntry.logEntries = []
                            }
                            selectedEntry.logEntries?.append(editedEntry)

                            do {
                                try context.save()
                            } catch {
                                logger.error("Failed saving edited entry: \(String(describing: error))")
                            }

                            isPresentingNewEntry = false
                        }
                    }
                    .presentationDetents([.large])
                }
                .sheet(isPresented: $isPresentingReflection, onDismiss: { isPresentingReflection = false } ) {
                    NavigationStack {
                        DailyReflectionSheet(day: $selectedEntry)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Settings", systemImage: "gearshape.fill") {
                            isPresentingSettings = true
                        }
                        .tint(.white)
                    }
                    ToolbarItem(placement: .principal) {
                        if showStats {
                            HStack {
                                VStack {
                                    Image(systemName: "calendar")
                                    Text("\(countDays)")
                                }
                                VStack {
                                    Image(systemName: "list.bullet.rectangle")
                                    Text("\(countLog)")
                                }
                                .padding(.leading, 4)
                            }
                            .font(.footnote)
                            .foregroundStyle(.white)
                        }
                    }
                }
                .task {
                    await initApplication()
                    updateToday()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        logger.trace("scene is now active. Updating today.")
                        updateToday()
                    }
                }
                .onChange(of: countLog) { old, new in
                    if new > old {
                        reviewService.considerRequesting(countLog: countLog) { requestReview() }
                    }
                }
               
                // The Add Button
                if Calendar.current.isDateInToday(selectedEntry.date) || !freezeHistory {
                    Button(action: { isPresentingNewEntry = true }) {
                        Image(systemName: "plus")
                            .font(.largeTitle)
                            .padding()
                            .glassCircle()
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                }
            }
            .sheet(isPresented: $isPresentingEditEntry) {
                NavigationStack {
                    LogEntrySheet(entry: $editingLogEntry, isEntryNew: .constant(false)) { editedEntry in
                        editingLogEntry.log = editedEntry.log
                        editingLogEntry.score = editedEntry.score
                        do {
                            try context.save()
                        } catch {
                            logger.error("Failed saving edited entry: \(String(describing: error))")
                        }
                        isPresentingEditEntry = false
                    }
                }
                .presentationDetents([.large])
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
        .ignoresSafeArea(.keyboard)
        .onOpenURL { url in
            switch url.host() {
            case "log":
                triggerScrollToToday = true
                isPresentingNewEntry = true
            case "reflect":
                triggerScrollToToday = true
                isPresentingReflection = true
            default:
                return
            }
        }
    }

    private func updateToday() {
        var descriptor = FetchDescriptor<DailyEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 1

        if let last = try? context.fetch(descriptor).first,
           Calendar.current.isDateInToday(last.date) {
            return
        }

        let newToday = DailyEntry(date: .now)
        logger.debug("Creating a new day: \(newToday.date)")
        context.insert(newToday)

        do {
            try context.save()
        } catch {
            logger.error("Failed saving new day: \(String(describing: error))")
        }

        selectedEntry = newToday
        triggerScrollToToday = true
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
        Task {
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
                    content.userInfo = ["url": "pulseapp://log"]
                    
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
                    
                    do {
                        try await UNUserNotificationCenter.current().add(request)
                    } catch {
                        logger.error("Failed to schedule notification: \(String(describing: error))")
                    }
                }
                
                if reflectionReminder, let reflectionReminderTime {
                    let content = UNMutableNotificationContent()
                    content.title = String(localized: "Reflection Time")
                    content.body = String(
                        localized: "It's time to reflect on your day!"
                    )
                    content.sound = .default
                    content.userInfo = ["url": "pulseapp://reflect"]
                    
                    let components = Calendar.current.dateComponents(
                        [.hour, .minute],
                        from: reflectionReminderTime
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
                    
                    do {
                        try await UNUserNotificationCenter.current().add(request)
                    } catch {
                        logger.error("Failed to schedule notification: \(String(describing: error))")
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
                        Compat.confirmButton(String(localized: "Close")) {
                            isPresentingSettings = false
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

