//
//  StatisticsSettingsView.swift
//  Pulse
//
//  Created by Marcus Raitner on 14.02.26.
//  Copyright © 2026 de.raitner. All rights reserved.
//

import SwiftUI
import SwiftData
import CloudKitSyncMonitor

struct StatisticsSettingsView: View {

    @Query private var allEntries: [DailyEntry]
    @Query private var allLogs: [DailyLogEntry]

    @StateObject private var syncMonitor = SyncMonitor.default

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
            HStack {
                Text("Number of days")
                Spacer()
                Text("\(countDays)")
            }
            HStack {
                Text("Number of moments")
                Spacer()
                Text("\(countLogs)")
            }
            Section("iCloud Sync") {
                VStack(alignment: .leading) {
                    VStack(alignment: .trailing) {
                        HStack {
                            Text("Status")
                            Spacer()
                            Image(systemName: syncMonitor.syncStateSummary.symbolName)
                                .foregroundColor(syncMonitor.syncStateSummary.symbolColor)
                        }
                        Text(syncMonitor.syncStateSummary.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Group {
                        if syncMonitor.hasSyncError {
                            if let error = syncMonitor.setupError {
                                Text("Unable to set up iCloud sync, changes won't be saved! \(error.localizedDescription)")
                            }
                            if let error = syncMonitor.importError {
                                Text("Import is broken: \(error.localizedDescription)")
                            }
                            if let error = syncMonitor.exportError {
                                Text("Export is broken - your changes aren't being saved! \(error.localizedDescription)")
                            }
                        } else if syncMonitor.isNotSyncing {
                            Text("Sync should be working, but isn't. Look for a badge on Settings or other possible issues.")
                        }
                    }
                    .foregroundStyle(.accent)
                    .padding(.top, 2)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        StatisticsSettingsView()
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.dark)
    }
}
