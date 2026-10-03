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
    
    // Export data
    @State private var isPresentingExport: Bool = false
    @State private var exportDocument: ExportJSONDocument?
    @State private var exportFilename: String = "pulse-export.json"
    @State private var exportErrorMessage: String?
    @State private var exportTimeRange: ExportTimeRange = .allTime
    @State private var exportStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var exportEndDate: Date = .now
    @State private var exportSelectedTags: Set<String> = []
    @State private var isExportOptionsExpanded: Bool = false
    
    @Query private var allEntries: [DailyEntry]
    @Query private var allTags: [Tag]
    @Query private var allKPIs: [KPITemplate]
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "GeneralSettingsView")
    
    private var isShowingExportError: Binding<Bool> {
        Binding(
            get: { exportErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    exportErrorMessage = nil
                }
            }
        )
    }
    
    /// Resolved on each access, so tapping Download always uses the range relative to now.
    private var exportDateRange: ClosedRange<Date>? {
        exportTimeRange.dateRange(now: .now, calendar: .current,
                                  customFrom: exportStartDate, customTo: exportEndDate)
    }
    
    private var exportTagsFilter: Set<String>? {
        exportSelectedTags.count == allTags.count ? nil : exportSelectedTags
    }
    
    private var appLockToggleTitle: LocalizedStringKey {
        let context = LAContext()
        // biometryType is only populated after canEvaluatePolicy has run at least once
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        
        switch context.biometryType {
        case .faceID: return "Require Face ID to open Pulse"
        case .touchID: return "Require Touch ID to open Pulse"
        default: return "Require your device passcode to open Pulse"
        }
    }
    
    private func exportTagBinding(for tagName: String) -> Binding<Bool> {
        Binding(
            get: { exportSelectedTags.contains(tagName) },
            set: { isSelected in
                if isSelected {
                    exportSelectedTags.insert(tagName)
                } else {
                    exportSelectedTags.remove(tagName)
                }
            }
        )
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
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Export")
                        Text("Download your data in a JSON file.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
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
                            exportErrorMessage = "Could not create data for download. Please try again."
                            isPresentingExport = false
                        }
                    } label: {
                        Text("Download")
                    }
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
                                        TagChipView(label: tag.name,
                                                    style: .selectable(isSelected: exportSelectedTags.contains(tag.name), onTap: { if exportSelectedTags.contains(tag.name) { exportSelectedTags.remove(tag.name) } else { exportSelectedTags.insert(tag.name) } } ))
                                    }
                                }
                            }
                        }
                    
                }
            }
        }
        .task {
            // A small migration step to transfer the old `freezeHistory` setting to the new one
            if let freezeHistory = UserDefaults.standard.value(forKey: AppStorageKeys.freezeHistory) {
                enableEditingHistory = !(freezeHistory as! Bool)
                UserDefaults.standard.removeObject(forKey: AppStorageKeys.freezeHistory)
            }
            // Default the export tag filter to "everything selected"
            exportSelectedTags = Set(allTags.map(\.name))
        }
        .onChange(of: allTags) { _, newTags in
            // Keep newly created tags selected by default so the filter still behaves as "no filter" until the user deselects one
            exportSelectedTags.formUnion(newTags.map(\.name))
            exportSelectedTags.formIntersection(newTags.map(\.name))
        }
        .alert("Download Failed", isPresented: isShowingExportError) {
            Button("OK") {
                exportErrorMessage = nil
            }
        } message: {
            Text(exportErrorMessage ?? "")
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
                    exportErrorMessage = "Could not create file. Please try again."
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
