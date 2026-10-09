//
//  StatisticsSettingsView.swift
//  Pulse
//
//  Created by Marcus Raitner on 14.02.26.
//  Copyright © 2026 de.raitner. All rights reserved.
//

import SwiftUI
import SwiftData

struct StatisticsSettingsView: View {

    @Query private var allEntries: [DailyEntry]
    @Query private var allLogs: [DailyLogEntry]

    @Environment(ICloudSyncMonitor.self) private var syncMonitor

    private var countDays: Int { allEntries.count }
    private var countLogs: Int { allLogs.count }

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
