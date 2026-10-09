//
//  StatisticsSettingsView.swift
//  Pulse
//
//  Created by Marcus Raitner on 14.02.26.
//  Copyright © 2026 de.raitner. All rights reserved.
//

import SwiftUI
import SwiftData
import OSLog

struct StatisticsSettingsView: View {

    @Environment(\.modelContext) private var context
    @Environment(ICloudSyncMonitor.self) private var syncMonitor

    // Counted with fetchCount: a @Query would load every entry and log into memory just to count them
    @State private var countDays = 0
    @State private var countLogs = 0

    private let logger = Logger(subsystem: "de.raitner.pulse", category: "StatisticsSettingsView")

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    Image(systemName: "chart.bar.horizontal.page.fill")
                        .titleLabelIcon(.gray)
                    Text("Statistics")
                        .font(.title2.bold())
                        .padding(.top, 4)
                    Text("See your current statistics here.")
                        .foregroundStyle(.secondary)

                }
            }
            LabeledContent("Number of days", value: countDays, format: .number)
            LabeledContent("Number of moments", value: countLogs, format: .number)
            Section("iCloud Sync") {
                SyncStatusRow(summary: syncMonitor.model.summary)
            }
        }
        // fetchCount does not update live, so count again after each completed sync, which can add data
        .task(id: syncMonitor.model.lastSuccess) {
            updateCounts()
        }
    }

    private func updateCounts() {
        do {
            countDays = try context.fetchCount(FetchDescriptor<DailyEntry>())
            countLogs = try context.fetchCount(FetchDescriptor<DailyLogEntry>())
        } catch {
            // keep the last counts rather than showing a misleading 0
            logger.error("Could not count the days and moments: \(error.localizedDescription)")
        }
    }
}

#Preview {
    NavigationStack {
        StatisticsSettingsView()
            .modelContainer(SampleData.shared.modelContainer)
            .environment(ICloudSyncMonitor())
            .preferredColorScheme(.dark)
    }
}
