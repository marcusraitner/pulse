//
//  ContentView.swift
//  collins score
//
//  Created by Marcus Raitner on 20.04.25.
//

import OSLog
import StoreKit
import SwiftData
import SwiftUI

enum ViewMode: String, CaseIterable {
    case day, week, month

    var systemImage: String {
        switch self {
        case .day: return "calendar.day.timeline.left"
        case .week: return "rectangle.grid.1x2"
        case .month: return "square.grid.3x3"
        }
    }
}

enum InlineFocusField: nonisolated Hashable {
    case tagField(timestamp: Date)
    case log(timestamp: Date)
}

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

    private var countLogs: Int { allLogs.count }

    @AppStorage(AppStorageKeys.notificationsEnabled) private
        var notificationsEnabled: Bool = true
    @AppStorage(AppStorageKeys.enableEditingHistory) private
        var enableEditingHistory: Bool = true
    @AppStorage(AppStorageKeys.reflectionReminder) private
        var reflectionReminder: Bool = true
    @AppStorage(AppStorageKeys.reflectionReminderTime) private
        var reflectionReminderTime: Date?
    @AppStorage(AppStorageKeys.viewMode) private var viewMode: ViewMode = .day

    //    @State private var viewMode: ViewMode = .day
    @State private var reviewService = ReviewService()
    @State private var selectedEntry: DailyEntry = DailyEntry(date: .now)
    @State private var triggerScrollToToday: Bool = false
    @State private var isPresentingSettings: Bool = false
    @State private var isPresentingNewEntry: Bool = false
    @State private var isPresentingReflection: Bool = false
    @State private var isPresentingInsights: Bool = false
    @State private var selectedDate: Date = .now
    @State private var scrollPosition: ScrollPosition = .init()
    @FocusState private var focus: InlineFocusField?

    private let logger = Logger(
        subsystem: "de.raitner.pulse",
        category: "ContentView"
    )

    var body: some View {
        NavigationStack {
            //            ZStack(alignment: .bottomTrailing) {
            //
            //                BackgroundImageView()
            //                    .ignoresSafeArea()
            //
            TabView(selection: $viewMode) {
                Tab("Day", systemImage: "calendar.day", value: .day) {
                    ScrollView {
                        VStack {
                            // Delete Button (only admin mode)
                            if featureFlags.adminEnabled {
                                Button("Delete Entry", systemImage: "trash") {
                                    context.delete(selectedEntry)
                                    context.saveOrLog(
                                        "Failure saving deleted entry",
                                        logger: logger
                                    )
                                }
                                .tint(.white)
                            }

                            // The daily reflection
                            DailyReflectionCard(day: selectedEntry) {
                                isPresentingReflection = true
                            }
                            .padding(.horizontal, 8)

                            Button {
                                let newEntry = DailyLogEntry(
                                    timestamp: .now,
                                    log: "",
                                    score: 0,
                                    entry: selectedEntry
                                )
                                context.insert(newEntry)
                                withAnimation {
                                    focus = .log(timestamp: newEntry.timestamp)
                                }
                            } label: {
                                Label("Add moment", systemImage: "plus.circle")
                            }
                            .padding(.vertical, 5)
                            .buttonStyle(.bordered)
                            
                            let logEntries = selectedEntry.logEntries?.sorted(by: {
                                $0.timestamp > $1.timestamp
                            }) ?? []
                            
                            ForEach(logEntries) { entry in
                                InlineLogEntryView(logEntry: entry, focused: $focus)
                            }
                            .padding(.horizontal, 8)
                        }
                        .scrollTargetLayout()
                    }
                    .scrollPosition($scrollPosition)
                    .defaultScrollAnchor(.top)
                    .safeAreaInset(edge: .top) {
                        // The timeline scroll view
                        VStack {
                            HorizontalTimelineView(
                                selectedEntry: $selectedEntry,
                                scrollToToday: $triggerScrollToToday
                            )
                        }
                        .padding(.vertical)
                        .background(.bar)
                    }
                    .onChange(of: focus) { old , new in
                        guard let new else { return }
                        
                        switch new {
                        case .log(let timestamp):
                            // only scroll if we are coming from another date
                            if case .log = old {
                                withAnimation {
                                    DispatchQueue.main.async {
                                        logger.info("Scrolling to date: \(timestamp)")
                                        scrollPosition.scrollTo(id: timestamp, anchor: .bottom)
                                    }
                                }
                            }
                        case .tagField(let timestamp):
                            logger.info("Tag Field selected for \(timestamp)")
                            return
                        }
                    }
                }

                Tab("Week", systemImage: "rectangle.split.3x1", value: .week) {
                    AggregatedTimelineView(
                        aggregationLevel: .week,
                        selectedStartDate: $selectedDate
                    )
                }

                Tab("Month", systemImage: "calendar", value: .month) {
                    AggregatedTimelineView(
                        aggregationLevel: .month,
                        selectedStartDate: $selectedDate
                    )
                }

            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(
                Text(formatDate(from: selectedDate, level: viewMode))
            )
            .onChange(of: selectedEntry) { _, new in
                selectedDate = new.date
                scrollPosition.scrollTo(edge: .top)
            }
            .onChange(of: selectedDate) { _, new in
                // TODO: find nearest DailyEntry and set it
            }
            //            .onReceive(
            //                NotificationCenter.default.publisher(
            //                    for: UIResponder.keyboardWillShowNotification
            //                )
            //            ) { _ in
            //                withAnimation {
            //                    scrollPosition = "pseudo"
            //                }
            //            }
            //            .onChange(of: scrollPosition) {
            //                logger.info("scrollPosition: \(scrollPosition as NSObject?)")
            //            }
            //            }
            .sheet(
                isPresented: $isPresentingSettings,
                onDismiss: setNotifications
            ) {
                settingsSheetStack
            }
            //            .sheet(isPresented: $isPresentingNewEntry) {
            //                NavigationStack {
            //                    LogEntrySheet(day: selectedEntry)
            //                }
            //                .presentationDetents([.large])
            //            }
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
                if focus != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark") {
                            withAnimation {
                                focus = nil
                            }
                        }
                    }
                } else {
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
                        Button("Settings", systemImage: "gearshape.fill") {
                            isPresentingSettings = true
                        }
                        .tint(.white)
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
                    reviewService.considerRequesting(countLog: countLogs) {
                        requestReview()
                    }
                }
            }
            //            .safeAreaInset(edge: .bottom, alignment: .trailing) {
            //                // The Add Button (day mode only)
            //                if !isInlineEditing && viewMode == .day
            //                    && (Calendar.current.isDateInToday(selectedEntry.date)
            //                        || enableEditingHistory)
            //                {
            //                    Button {
            //                        withAnimation {
            //                            isInlineEditing = true
            //                            scrollPosition = "pseudo"
            //                        }
            //                    } label: {
            //                        Image(systemName: "plus")
            //                            .font(.largeTitle)
            //                            .padding()
            //                            .glassCircle()
            //                            .foregroundStyle(.white)
            //                    }
            //                    .contentShape(Circle())
            //                    .buttonStyle(.plain)
            //                    .padding(.trailing, 20)
            //                }
            //            }
            //            .safeAreaInset(edge: .top) {
            //                if isInlineEditing {
            //                    HStack {
            //                        Button("Cancel", systemImage: "xmark") {
            //                            isInlineEditing = false
            //                            scrollPosition = ""
            //                        }
            //                        .labelStyle(.iconOnly)
            //                        .buttonStyle(.bordered)
            //                        Spacer()
            //                        Button("Save", systemImage: "checkmark") {
            //                        }
            //                        .labelStyle(.iconOnly)
            //                        .buttonStyle(.borderedProminent)
            //                    }
            //                    .padding(.horizontal)
            //                    .padding(.bottom)
            //                    .background(.bar)
            //                }
            //            }
            //            .background {
            //                BackgroundImageView()
            //                    .ignoresSafeArea()
            //            }
            #if DEBUG
                // Expose an accessibility identifier
                .accessibilityIdentifier("dateView")
                // and a values containing the selectedEntry for UI Tests
                .accessibilityValue(
                    Text(
                        "selectedEntry:\(DateFormatHelper.formatDate(selectedEntry.date))"
                    )
                )
            #endif  // DEBUG only for UI Tests
        }
        //        .border(Color.cyan, width: 1)

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

    private func formatDate(from date: Date, level: ViewMode) -> String {
        var str: String
        switch level {
        case .day:
            str = date.formatted(.dateTime.weekday().day().month().year())
        case .week:
            let cal = Calendar.current
            let start =
                cal.dateInterval(of: .weekOfYear, for: date)?.start ?? date
            let end = cal.date(byAdding: .day, value: 6, to: start) ?? start

            str =
                "\(start.formatted(.dateTime.day().month(.defaultDigits).year())) – \(end.formatted(.dateTime.day().month(.defaultDigits).year()))"
        case .month:
            str = date.formatted(.dateTime.month(.wide).year())
        }
        return str
    }

    /// Re-schedules local notifications from current `AppStorage` values.
    /// Called when the settings sheet is dismissed.
    private func setNotifications() {
        NotificationScheduler.setNotifications(
            notificationsEnabled: notificationsEnabled,
            notificationTimes: UserDefaults.standard.array(
                forKey: AppStorageKeys.notificationTimes
            ) as? [Date] ?? [],
            reflectionReminder: reflectionReminder,
            reflectionReminderTime: reflectionReminderTime
        )
    }

    /// Ensures today's `DailyEntry` exists, creating and inserting one if it is missing.
    /// Scrolls the timeline to today after creating a new entry.
    private func updateToday() {
        var descriptor = FetchDescriptor<DailyEntry>(sortBy: [
            SortDescriptor(\.date, order: .reverse)
        ])
        descriptor.fetchLimit = 1

        if let last = try? context.fetch(descriptor).first,
            Calendar.current.isDateInToday(last.date)
        {
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

        // Request authorization for notifications
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound])
        } catch {
            logger.error(
                "Error NotificationCenter: \(error.localizedDescription)"
            )
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
