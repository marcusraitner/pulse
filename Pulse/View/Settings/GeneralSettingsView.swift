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

struct GeneralSettingsView: View {

    @AppStorage(AppStorageKeys.enableEditingHistory) private var enableEditingHistory: Bool = false

    // Export data
    @State private var isPresentingExport: Bool = false
    @State private var exportDocument: ExportJSONDocument?
    @State private var exportFilename: String = "pulse-export.json"
    @State private var exportErrorMessage: String?
    @State private var exportDateFilterEnabled: Bool = false
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

    private var exportDateRange: ClosedRange<Date>? {
        guard exportDateFilterEnabled else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: min(exportStartDate, exportEndDate))
        let endOfEndDay = calendar.date(
            byAdding: DateComponents(day: 1, second: -1),
            to: calendar.startOfDay(for: max(exportStartDate, exportEndDate))
        ) ?? max(exportStartDate, exportEndDate)
        return start...endOfEndDay
    }

    private var exportTagsFilter: Set<String>? {
        exportSelectedTags.count == allTags.count ? nil : exportSelectedTags
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

                HStack {
                    VStack(alignment: .leading) {
                        Text("Backup")
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
                    Toggle(isOn: $exportDateFilterEnabled) {
                        Text("Restrict to date range")
                    }
                    if exportDateFilterEnabled {
                        DatePicker("From", selection: $exportStartDate, displayedComponents: .date)
                        DatePicker("To", selection: $exportEndDate, displayedComponents: .date)
                    }

                    if !allTags.isEmpty {
                        Text("Tags")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, exportDateFilterEnabled ? 4 : 0)
                        ForEach(allTags) { tag in
                            Toggle(tag.name, isOn: exportTagBinding(for: tag.name))
                        }
                    }
                }
                .animation(.default, value: isExportOptionsExpanded)
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
