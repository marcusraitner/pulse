//
//  GeneralSettingsView.swift
//  Pulse
//
//  Created by Marcus Raitner on 14.02.26.
//  Copyright © 2026 de.raitner. All rights reserved.
//

import SwiftUI
import SwiftData
import OSLog
import UniformTypeIdentifiers
import LocalAuthentication

struct GeneralSettingsView: View {
    
    @AppStorage(AppStorageKeys.enableEditingHistory) private var enableEditingHistory: Bool = false
    @AppStorage(AppStorageKeys.appLockEnabled) private var appLockEnabled: Bool = false
    @AppStorage(AppStorageKeys.healthMoodLogging) private var healthMoodLogging: Bool = false
    @AppStorage(AppStorageKeys.mindfulMinutesLogging) private var mindfulMinutesLogging: Bool = false

    // Re-read whenever the app becomes active: access can only be granted in Settings
    @State private var isHealthAccessDenied: Bool = false
    @State private var isMindfulAccessDenied: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    // Export data
    @State private var isPresentingExport: Bool = false
    @State private var exportDocument: ExportJSONDocument?
    @State private var exportFilename: String = "pulse-export.json"
    @State private var isShowingExportError: Bool = false
    @State private var exportErrorMessage: LocalizedStringResource?
    @State private var exportTimeRange: ExportTimeRange = .allTime
    @State private var exportStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var exportEndDate: Date = .now
    @State private var exportSelectedTags: Set<String> = []
    @State private var isExportOptionsExpanded: Bool = false

    // Read once when the screen appears; asking the system on every body pass is wasteful
    @State private var biometryType: LABiometryType = .none
    
    @Query private var allEntries: [DailyEntry]
    @Query private var allTags: [Tag]
    @Query private var allKPIs: [KPITemplate]
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "GeneralSettingsView")
    
    private func showExportError(_ message: LocalizedStringResource) {
        exportErrorMessage = message
        isShowingExportError = true
    }

    /// Resolved on each access, so tapping Download always uses the range relative to now.
    private var exportDateRange: ClosedRange<Date>? {
        exportTimeRange.dateRange(now: .now, calendar: .current,
                                  customFrom: exportStartDate, customTo: exportEndDate)
    }
    
    private var exportTagsFilter: Set<String>? {
        exportSelectedTags.count == allTags.count ? nil : exportSelectedTags
    }

    private func toggleExportTag(_ tagName: String) {
        exportSelectedTags.formSymmetricDifference([tagName])
    }

    /// A small migration step to transfer the old `freezeHistory` setting to the new one.
    private func migrateFreezeHistory() {
        let defaults = UserDefaults.standard
        guard let freezeHistory = defaults.object(forKey: AppStorageKeys.freezeHistory) as? Bool else { return }
        enableEditingHistory = !freezeHistory
        defaults.removeObject(forKey: AppStorageKeys.freezeHistory)
    }

    /// Disables each Health toggle while its access is denied, and turns it off if access was
    /// revoked in Settings, so a toggle never claims Pulse is writing when it cannot.
    /// HealthKit grants access per data type, so the two toggles are checked separately.
    private func refreshHealthAccess() {
        isHealthAccessDenied = HealthMoodLogger.isAccessDenied
        if isHealthAccessDenied {
            healthMoodLogging = false
        }
        isMindfulAccessDenied = MindfulSessionLogger.isAccessDenied
        if isMindfulAccessDenied {
            mindfulMinutesLogging = false
        }
    }

    private var appLockToggleTitle: LocalizedStringKey {
        switch biometryType {
        case .faceID: "Require Face ID to open Pulse"
        case .touchID: "Require Touch ID to open Pulse"
        default: "Require your device passcode to open Pulse"
        }
    }
    
    private func prepareExport() {
        do {
            let payload = ExportPayloadMapper.exportPayload(
                from: allEntries,
                kpiTemplates: allKPIs,
                dateRange: exportDateRange,
                tags: exportTagsFilter
            )
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(payload)

            exportDocument = .init(data: data)
            exportFilename = "pulse-export-\(DateFormatHelper.formatDate(.now)).json"
            isPresentingExport = true

        } catch {
            logger.error("Failed to create export payload: \(error.localizedDescription)")
            showExportError("Could not create data for download. Please try again.")
            isPresentingExport = false
        }
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Image(systemName: "gear")
                        .titleLabelIcon(.gray)
                    Text("General")
                        .font(.title2.bold())
                        .padding(.top, 4)
                    Text("Adjust general settings here.")
                        .foregroundStyle(.secondary)
                    
                }
                
                Toggle(isOn: $enableEditingHistory) {
                    Text("Edit past days and moments")
                    Text("Enable this option to be able to add, delete, or edit moments for past days.")
                    
                }
                
                Toggle(isOn: $appLockEnabled) {
                    Text(appLockToggleTitle)
                    Text("Pulse will lock whenever you leave the app and ask you to unlock it again.")
                }
            }
            if HealthMoodLogger.isAvailable {
                Section {
                    Toggle(isOn: $healthMoodLogging) {
                        Text("Save moods to Apple Health")
                        Text("Each new or edited moment is saved as a State of Mind in the Health app. Pulse never reads data from Health.")
                    }
                    .disabled(isHealthAccessDenied)

                    Toggle(isOn: $mindfulMinutesLogging) {
                        Text("Log reflections as Mindful Minutes")
                        Text("Time spent in the reflection with the app open is saved as Mindful Minutes, from one minute up to 30 minutes per session. Only saved reflections count.")
                    }
                    .disabled(isMindfulAccessDenied)
                } footer: {
                    if isHealthAccessDenied || isMindfulAccessDenied {
                        Text("Pulse is not allowed to write to Health. Allow it in Settings under Privacy & Security > Health > Pulse.")
                    }
                }
            }
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Export")
                        Text("Download your data in a JSON file.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Download", action: prepareExport)
                    .disabled(exportSelectedTags.isEmpty)
                    .buttonStyle(.bordered)
                    .padding(.leading, 10)
                }
                
                DisclosureGroup("Export options", isExpanded: $isExportOptionsExpanded) {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Time range", selection: $exportTimeRange) {
                            ForEach(ExportTimeRange.allCases, id: \.self) { range in
                                Text(range.label)
                            }
                        }
                        // Reserves space for the widest option so the menu-style value label doesn't
                        // reflow (and briefly render at the wrong position) when switching between
                        // options of very different widths, e.g. "This week" vs. "Custom range".
                        .frame(minWidth: 150, alignment: .trailing)
                        .padding(.bottom, 4)
                        
                        if exportTimeRange == .custom {
                            DatePicker("From", selection: $exportStartDate, displayedComponents: .date)
                            DatePicker("To", selection: $exportEndDate, displayedComponents: .date)
                        }
                    }
                    if !allTags.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Filter by tag")
                            FlowLayout {
                                ForEach(allTags) { tag in
                                    TagChipView(
                                        label: tag.name,
                                        style: .selectable(
                                            isSelected: exportSelectedTags.contains(tag.name),
                                            onTap: { toggleExportTag(tag.name) } ))
                                }
                            }
                            if exportSelectedTags.isEmpty {
                                Text("Select at least one tag.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .animation(.default, value: isExportOptionsExpanded)
            }
        }
        .task {
            biometryType = deviceBiometryType()
            migrateFreezeHistory()
            // Default the export tag filter to "everything selected"
            exportSelectedTags = Set(allTags.map(\.name))
            refreshHealthAccess()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshHealthAccess() }
        }
        .onChange(of: healthMoodLogging) { _, isEnabled in
            // Turning off only stops new writes; samples already in Health stay there
            guard isEnabled else { return }
            Task {
                if !(await HealthMoodLogger.requestAuthorization()) {
                    healthMoodLogging = false
                }
                refreshHealthAccess()
            }
        }
        .onChange(of: mindfulMinutesLogging) { _, isEnabled in
            // Turning off only stops new writes; sessions already in Health stay there
            guard isEnabled else { return }
            Task {
                if !(await MindfulSessionLogger.requestAuthorization()) {
                    mindfulMinutesLogging = false
                }
                refreshHealthAccess()
            }
        }
        .onChange(of: allTags) { _, newTags in
            // Keep newly created tags selected by default so the filter still behaves as "no filter" until the user deselects one
            exportSelectedTags.formUnion(newTags.map(\.name))
            exportSelectedTags.formIntersection(newTags.map(\.name))
        }
        .alert("Download Failed", isPresented: $isShowingExportError) {
        } message: {
            if let exportErrorMessage {
                Text(exportErrorMessage)
            }
        }
        .fileExporter(
            isPresented: $isPresentingExport,
            document: exportDocument,
            contentType: .json,
            defaultFilename: exportFilename) { result in
                switch result {
                case .success:
                    exportDocument = nil
                case .failure(let error):
                    logger.error("Failed to export to file: \(error.localizedDescription)")
                    showExportError("Could not create file. Please try again.")
                }
            }
    }
}

#Preview {
    NavigationStack {
        GeneralSettingsView()
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.dark)
    }
}
