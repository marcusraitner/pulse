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

enum ViewMode: String, CaseIterable {
    case day, week, month

    var systemImage: String {
        switch self {
        case .day:   return "calendar.day.timeline.left"
        case .week:  return "rectangle.grid.1x2"
        case .month: return "square.grid.3x3"
        }
    }
}

/// Root view that orchestrates the timeline, selected-date display, log entries,
/// reflection card, and FAB. Also owns sheet presentation for settings, new/edit
/// entry, and reflection, and handles deep-link URLs (`pulseapp://log`, `pulseapp://reflect`).
struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.featureFlags) private var featureFlags
    @Environment(\.requestReview) private var requestReview
    
    @Query(sort: \DailyEntry.date, order: .forward) private var allEntries: [DailyEntry]
    @Query private var allLogs: [DailyLogEntry]
    
    private var countLogs: Int { allLogs.count }
    
    @AppStorage(AppStorageKeys.notificationsEnabled) private var notificationsEnabled: Bool = true
    @AppStorage(AppStorageKeys.enableEditingHistory) private var enableEditingHistory: Bool = true
    @AppStorage(AppStorageKeys.reflectionReminder) private var reflectionReminder: Bool = true
    @AppStorage(AppStorageKeys.reflectionReminderTime) private var reflectionReminderTime: Date?
    @AppStorage(AppStorageKeys.viewMode) private var viewMode: ViewMode = .day
    @AppStorage(AppStorageKeys.initialSweepDone) private var initialSweepDone: Bool = false
    @AppStorage(AppStorageKeys.showEmptyDays) private var showEmptyDays: Bool = false
    
    @State private var reviewService = ReviewService()
    @State private var selectedEntry: DailyEntry = DailyEntry(date: .now)
    @State private var triggerScrollToToday: Bool = false
    @State private var isPresentingSettings: Bool = false
    @State private var isPresentingNewEntry: Bool = false
    @State private var isPresentingReflection: Bool = false
    @State private var isPresentingInsights: Bool = false
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "ContentView")

    
    var body: some View {
        NavigationStack {
                
                TabView(selection: $viewMode) {
                    
                    Tab("Day", systemImage: "calendar.day", value: .day) {
                        ZStack(alignment: .bottomTrailing) {
                            
                            BackgroundImageView()
                            ScrollView {
                                LazyVStack {
                                    
                                    
                                    // Delete Button (only admin mode)
                                    if featureFlags.adminEnabled {
                                        Button("Delete Entry", systemImage: "trash") {
                                            context.delete(selectedEntry)
                                            context.saveOrLog("Failure saving deleted entry", logger: logger)
                                        }
                                        .tint(.white)
                                    }
                                    
                                    
                                    
                                    // The daily reflection
                                    DailyReflectionCard(day: selectedEntry) {
                                        isPresentingReflection = true
                                    }
                                    .padding(.horizontal, 8)
                                    
                                    // The log entries for this day
                                    LogEntriesView(day: selectedEntry)
                                        .padding(.horizontal, 8)
                                }
                            }
                            .safeAreaInset(edge: .top) {
                                VStack {
                                    // The currently selected date
                                    SelectedDateView(date: selectedEntry.date)
                                        .padding(.horizontal)
                                        .padding(.top)
                                    
                                    // The timeline scroll view
                                    HorizontalTimelineView(selectedEntry: $selectedEntry, scrollToToday: $triggerScrollToToday)
                                        .padding(.vertical)
                                }
                                .background(.bar)
                            }
                            
                            
                            // The Add Button (day mode only)
                            if viewMode == .day && (Calendar.current.isDateInToday(selectedEntry.date) || enableEditingHistory) {
                                Button(action: { isPresentingNewEntry = true }) {
                                    Image(systemName: "plus")
                                        .font(.largeTitle)
                                        .padding()
                                        .glassCircle()
                                        .foregroundStyle(.white)
                                }
                                .contentShape(Circle())
                                .buttonStyle(.plain)
                                .padding(.trailing, 8)
                            }
                        }
                    }
                    
                    Tab("Week", systemImage: "rectangle.split.3x1", value: .week) {
                        ZStack(alignment: .bottomTrailing) {
                            
                            BackgroundImageView()
                            
                            AggregatedTimelineView(aggregationLevel: .week)
                        }
                    }
                    
                    Tab("Month", systemImage: "calendar", value: .month) {
                        ZStack(alignment: .bottomTrailing) {
                            
                            BackgroundImageView()
                            
                            AggregatedTimelineView(aggregationLevel: .month)
                        }
                    }
                }
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
                .sheet(isPresented: $isPresentingInsights) {
                    // #available required by compiler: InsightsView is @available(iOS 26, *)
                    if #available(iOS 26, *) {
                        NavigationStack {
                            InsightsView()
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if featureFlags.foundationModelsAvailable {
                            Button {
                                isPresentingInsights = true
                            } label: {
                                Image(systemName: "sparkles")
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Settings",
                               systemImage: showEmptyDays ?
                               "line.3.horizontal.decrease.circle"
                               : "line.3.horizontal.decrease.circle.fill") {
                            showEmptyDays.toggle()
                        }
                        .tint(.white)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Settings", systemImage: "gearshape.fill") {
                            isPresentingSettings = true
                        }
                        .tint(.white)
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
    #if DEBUG
                // Expose an accessibility identifier
                .accessibilityIdentifier("dateView")
                // and a values containing the selectedEntry for UI Tests
                .accessibilityValue(
                    Text("selectedEntry:\(DateFormatHelper.formatDate(selectedEntry.date))")
                )
    #endif  // DEBUG only for UI Tests

                
            
        }
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
        addMissingEntries()
        
        guard let newToday = allEntries.last else { return }

        // TODO: We should not scroll every time, but only when today is fresh
        selectedEntry = newToday
        triggerScrollToToday = true
    }
   
    private func fillGap(from start: Date, to end: Date) {
        var entryDates = Set(allEntries.map { Calendar.current.startOfDay(for: $0.date) })
        var current = end
        
        // going backwards from today; start can be excluded as it already exists
        while current > start {
            if !entryDates.contains(current) {
                let newEntry = DailyEntry(date: current)
                logger.info("Adding new entry for \(current)")
                entryDates.insert(current)
                context.insert(newEntry)
            }
            
            guard let next = Calendar.current.date(byAdding: .day, value: -1, to: current) else {
                // very unlikely this happens, but if so, we just stop filling
                logger.warning("adding 1 to \(current) resulted in nil")
                break
            }
            
            current = next
        }
        
        context.saveOrLog("Error saving missing entries", logger: logger)
    }
    
    
    private func addMissingEntries() {
        // add first entry
        guard let lastEntry = allEntries.last else {
            context.insert(DailyEntry(date: .now))
            context.saveOrLog("Added first entry", logger: logger)
            return
        }
        
        let start = initialSweepDone ? lastEntry.date : allEntries.first!.date
        let end = Calendar.current.startOfDay(for: .now)
        
        fillGap(from: start, to: end)
        
        initialSweepDone = true
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
        .environment(\.featureFlags, FeatureFlags(adminEnabled: false))
        .preferredColorScheme(.dark)
}

