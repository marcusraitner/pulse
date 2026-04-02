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

/// Root view that orchestrates the timeline, selected-date display, log entries,
/// reflection card, and FAB. Also owns sheet presentation for settings, new/edit
/// entry, and reflection, and handles deep-link URLs (`pulseapp://log`, `pulseapp://reflect`).
struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.featureFlags) private var featureFlags
    @Environment(\.requestReview) private var requestReview
    
    @Query private var allEntries: [DailyEntry]
    @Query private var allLogs: [DailyLogEntry]
    
    private var countDays: Int { allEntries.count }
    private var countLogs: Int { allLogs.count }

    
    @AppStorage(AppStorageKeys.notificationsEnabled) private var notificationsEnabled: Bool = true
    @AppStorage(AppStorageKeys.freezeHistory) private var freezeHistory: Bool = true
    @AppStorage(AppStorageKeys.showStats) private var showStats: Bool = true
    @AppStorage(AppStorageKeys.reflectionReminder) private var reflectionReminder: Bool = true
    @AppStorage(AppStorageKeys.reflectionReminderTime) private var reflectionReminderTime: Date?
    
    @State private var reviewService = ReviewService()
    @State private var selectedEntry: DailyEntry = DailyEntry(date: .now)
    @State private var triggerScrollToToday: Bool = false
    @State private var isPresentingSettings: Bool = false
    @State private var isPresentingNewEntry: Bool = false
    @State private var isPresentingReflection: Bool = false
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "ContentView")

    
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
                                context.saveOrLog("Failure saving deleted entry", logger: logger)
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
                        LogEntriesView(day: selectedEntry)
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
                        LogEntrySheet(day: selectedEntry)
                    }
                    .presentationDetents([.large])
                }
                .sheet(isPresented: $isPresentingReflection) {
                    NavigationStack {
                        DailyReflectionSheet(day: selectedEntry)
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
                                    Text("\(countLogs)")
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
                .onChange(of: countLogs) { old, new in
                    if new > old {
                        reviewService.considerRequesting(countLog: countLogs) { requestReview() }
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
    
    /// Re-schedules local notifications from current `AppStorage` values.
    /// Called when the settings sheet is dismissed.
    private func setNotifications() {
        NotificationScheduler.setNotifications(
            notificationsEnabled: notificationsEnabled,
            notificationTimes: UserDefaults.standard.array(forKey: AppStorageKeys.notificationTimes) as? [Date] ?? [],
            reflectionReminder: reflectionReminder,
            reflectionReminderTime: reflectionReminderTime)
    }

    /// Ensures today's `DailyEntry` exists, creating and inserting one if it is missing.
    /// Scrolls the timeline to today after creating a new entry.
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
        context.saveOrLog("Failure while saving new day", logger: logger)
        selectedEntry = newToday
        triggerScrollToToday = true
    }

    /// Performs one-time startup work: applies debug launch arguments and requests
    /// notification authorisation. Called once from `.task` on first appearance.
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

    
    /// The `NavigationStack`-wrapped settings sheet with a Close toolbar button.
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

