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

    private var syncSymbol: (name: String, color: Color) {
        switch syncMonitor.model.summary {
        case .synced: ("icloud", .green)
        case .waiting: ("icloud", .gray)
        case .syncing, .busy: ("arrow.clockwise.icloud", .gray)
        case .offline: ("bolt.horizontal.icloud", .gray)
        case .noAccount: ("lock.icloud", .red)
        case .problem: ("exclamationmark.icloud", .red)
        }
    }

    /// Problems the user has to act on are highlighted; waiting states stay quiet.
    private var syncNeedsAttention: Bool {
        switch syncMonitor.model.summary {
        case .noAccount, .problem: true
        default: false
        }
    }

    @ViewBuilder private var syncDescription: some View {
        switch syncMonitor.model.summary {
        case .synced(let date):
            // refreshes so "1 minute ago" doesn't go stale while the screen is open
            TimelineView(.periodic(from: .now, by: 30)) { _ in
                Text("Last synced \(Self.relativeFormatter.localizedString(for: date, relativeTo: .now))")
            }
        case .syncing: Text("Syncing…")
        case .waiting: Text("Waiting for the first sync")
        case .offline: Text("Offline – will sync when you're back online")
        case .busy: Text("iCloud is busy – will try again")
        case .noAccount: Text("No iCloud account – changes stay on this device")
        case .problem(.other(let message)): Text("Sync problem: \(message)")
        case .problem: Text("iCloud storage is full – changes aren't being saved")  // the only other problem
        }
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

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
                VStack(alignment: .trailing) {
                    HStack {
                        Text("Status")
                        Spacer()
                        Image(systemName: syncSymbol.name)
                            .foregroundStyle(syncSymbol.color)
                    }
                    syncDescription
                        .font(.caption)
                        .foregroundStyle(syncNeedsAttention ? AnyShapeStyle(.accent) : AnyShapeStyle(.secondary))
                        .multilineTextAlignment(.trailing)
                }
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
