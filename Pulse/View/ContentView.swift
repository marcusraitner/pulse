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
        case .week:  return "rectangle.split.3x1"
        case .month: return "calendar"
        }
    }
}

/// Day-starts between `start` and `end` that have no entry yet, newest first.
/// `start` itself is excluded — it already exists.
func missingEntryDates(existing: [Date], from start: Date, to end: Date,
                       calendar: Calendar = .current) -> [Date] {
    let have = Set(existing.map { calendar.startOfDay(for: $0) })
    let firstDay = calendar.startOfDay(for: start)
    var missing: [Date] = []
    var current = calendar.startOfDay(for: end)

    while current > firstDay {
        if !have.contains(current) { missing.append(current) }

        guard let previous = calendar.date(byAdding: .day, value: -1, to: current) else { break }
        // re-normalise: day arithmetic lands off midnight where DST shifts at 00:00
        let previousDay = calendar.startOfDay(for: previous)
        guard previousDay < current else { break }  // ponytail: paranoia, no hang if it ever stalls
        current = previousDay
    }

    return missing
}

/// Root view that orchestrates the timeline, selected-date display, log entries,
/// reflection card, and FAB. Also owns sheet presentation for settings, new/edit
/// entry, and reflection, and handles deep-link URLs (`pulseapp://log`, `pulseapp://reflect`).
struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.featureFlags) private var featureFlags
    @Environment(\.requestReview) private var requestReview
    @Environment(FilterState.self) private var filterState
    
    @Query(sort: \DailyEntry.date, order: .forward) private var allEntries: [DailyEntry]
    @Query private var allLogs: [DailyLogEntry]
    @Query(sort: \Tag.name, order: .forward) private var tags: [Tag]
    
    private var countLogs: Int { allLogs.count }
    
    @AppStorage(AppStorageKeys.notificationsEnabled) private var notificationsEnabled: Bool = true
    @AppStorage(AppStorageKeys.enableEditingHistory) private var enableEditingHistory: Bool = true
    @AppStorage(AppStorageKeys.reflectionReminder) private var reflectionReminder: Bool = true
    @AppStorage(AppStorageKeys.reflectionReminderTime) private var reflectionReminderTime: Date?
    @AppStorage(AppStorageKeys.initialSweepDone) private var initialSweepDone: Bool = false
    @AppStorage(AppStorageKeys.showEmptyDays) private var showEmptyDays: Bool = false
    @AppStorage(AppStorageKeys.sortAscending) private var sortAscending: Bool = true
    
    @State private var reviewService = ReviewService()
    @State private var selectedEntry: DailyEntry = DailyEntry(date: .now)
    @State private var triggerScrollToToday: Bool = false
    @State private var isPresentingSettings: Bool = false
    @State private var isPresentingNewEntry: Bool = false
    @State private var isPresentingReflection: Bool = false
    @State private var isPresentingInsights: Bool = false
    @State private var viewMode: ViewMode = .day

    private let logger = Logger(subsystem: "de.raitner.pulse", category: "ContentView")

    
    var body: some View {
        @Bindable var filterState = filterState
        
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                                
                if viewMode == .day {
                    ScrollView {
                        VStack {
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
                    .safeAreaBar(edge: .top) {
                        VStack {
                            // The timeline scroll view
                            HorizontalTimelineView(selectedEntry: $selectedEntry, scrollToToday: $triggerScrollToToday)
                                .padding(.top)
                            SelectedDateView(date: selectedEntry.date)
                                .padding(.bottom)
                                .padding(.top, 4)
                        }
                    }
                } else {
                    AggregatedTimelineView(aggregationLevel: viewMode == .week ? .week : .month)
                }
                
                BackgroundImageView()
                    .zIndex(-1)

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
                NavigationStack {
                    InsightsView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        switch viewMode {
                        case .day:
                            viewMode = .week
                        case .week:
                            viewMode = .month
                        case .month:
                            viewMode = .day
                        }
                    } label: {
                        ZStack {
                            ForEach(ViewMode.allCases, id: \.self) { mode in
                                Image(systemName: mode.systemImage)
                                    .hidden()
                            }
                            
                            Image(systemName: viewMode.systemImage)
                                .fontWeight(.medium)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .animation(.snappy(duration: 0.25), value: viewMode)
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    if !tags.isEmpty {
                        HStack(spacing: 8) {
                            Button {
                                filterState.isFilterActive.toggle()
                                if filterState.selectedTag == nil {
                                    filterState.selectedTag = tags.first!.name
                                }
                            } label: {
                                Image(systemName: filterState.isFilterActive ? "tag.fill" : "tag")
                                    .fontWeight(.medium)
                                    .foregroundStyle(filterState.isFilterActive ? .accent : .white)
                                    .padding(6)
                                    .padding(.vertical, 2)
                            }
                            .buttonStyle(.plain)
                            
                            if filterState.isFilterActive {
                                Menu {
                                    Picker("Filter by", selection: $filterState.selectedTag) {
                                        ForEach(tags, id: \.self) { tag in
                                            Text(tag.name).tag(tag.name)
                                        }
                                    }
                                    .pickerStyle(.inline)
                                } label: {
                                    if let selectedTag = filterState.selectedTag {
                                        HStack(spacing: 4) {
                                            Text(selectedTag)
                                                .fontWeight(.semibold)
                                            Image(systemName: "chevron.down")
                                                .font(.caption2)
                                        }
                                        .foregroundStyle(.primary)
                                        .padding(.trailing, 4)
                                    }
                                }
                            }
                        }
                        .geometryGroup()
                    }
                }
                
                ToolbarSpacer(.flexible, placement: .bottomBar)
                
                ToolbarItem(placement: .bottomBar) {
                    // The Add Button (day mode only)
                    if viewMode == .day && (Calendar.current.isDateInToday(selectedEntry.date) || enableEditingHistory) {
                        Button(action: { isPresentingNewEntry = true }) {
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.accent)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section("Appearance") {
                            Toggle("Show empty days",
                                   systemImage: "calendar.day",
                                   isOn: $showEmptyDays)
                            
                            Picker(selection: $sortAscending) {
                                Text("Newest first").tag(false)
                                Text("Oldest first").tag(true)
                            } label: {
                                Label("Order", systemImage: "arrow.up.arrow.down")
                                Text(sortAscending ? "Oldest first" : "Newest first")
                            }
                            .pickerStyle(.menu)

                        }
                        
                        Section {
                            Button("Open Settings", systemImage: "gearshape.fill") {
                                isPresentingSettings = true
                            }
                            
                            if featureFlags.foundationModelsAvailable {
                                Button("AI Coach", systemImage: "sparkles") {
                                    isPresentingInsights = true
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .task {
            await initApplication()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                logger.trace("scene is now active.")
                addMissingEntries()
            }
        }
        .onChange(of: countLogs) { old, new in
            if new > old {
                reviewService.considerRequesting(countLog: countLogs) { requestReview() }
            }
        }
        .onChange(of: viewMode) { _, new in
            if new == .day {
                triggerScrollToToday = true
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
        .onOpenURL { url in
            switch url.host() {
            case "log":
                triggerScrollToToday = true
                viewMode = .day
                isPresentingNewEntry = true
            case "reflect":
                triggerScrollToToday = true
                viewMode = .day
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
   
    /// Creates a `DailyEntry` for every day that has none, so the timeline has no holes.
    /// Runs on every activation, hence the shortcut: after the one-time sweep over the
    /// whole history only the tail since the newest entry can be missing.
    private func addMissingEntries() {
        guard let oldest = allEntries.first, let newest = allEntries.last else {
            context.insert(DailyEntry(date: Calendar.current.startOfDay(for: .now)))
            context.saveOrLog("Added first entry", logger: logger)
            return
        }

        let missing = initialSweepDone
            ? missingEntryDates(existing: [newest.date], from: newest.date, to: .now)
            : missingEntryDates(existing: allEntries.map(\.date), from: oldest.date, to: .now)

        for date in missing {
            logger.info("Adding new entry for \(date)")
            context.insert(DailyEntry(date: date))
        }

        if !missing.isEmpty {
            context.saveOrLog("Error saving missing entries", logger: logger)
        }

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
        
        logger.info("Application initialised; scrolling to today")
        triggerScrollToToday = true
    }

    
    /// The `NavigationStack`-wrapped settings sheet with a Close toolbar button.
    private var settingsSheetStack: some View {
        NavigationStack {
            SettingsView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(role: .confirm) {
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

