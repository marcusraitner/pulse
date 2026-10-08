//
//  SyncStatusRow.swift
//  Pulse
//
//  Created by Marcus Raitner on 08.10.26.
//

import SwiftUI

/// The "Status" row of the iCloud sync section: an icon, and below it what the sync is doing.
struct SyncStatusRow: View {
    let summary: SyncStatusModel.Summary

    private var symbol: (name: String, color: Color) {
        switch summary {
        case .synced: ("checkmark.icloud", .green)
        case .waiting: ("icloud", .gray)
        case .syncing, .busy: ("arrow.clockwise.icloud", .gray)
        case .offline: ("bolt.horizontal.icloud", .gray)
        case .noAccount: ("lock.icloud", .red)
        case .storageFull, .problem: ("exclamationmark.icloud", .red)
        }
    }

    /// Problems the user has to act on are highlighted; waiting states stay quiet.
    private var needsAttention: Bool {
        switch summary {
        case .noAccount, .storageFull, .problem: true
        default: false
        }
    }

    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Text("Status")
                Spacer()
                Image(systemName: symbol.name)
                    .foregroundStyle(symbol.color)
                    .accessibilityHidden(true)
            }
            statusText
                .font(.caption)
                .foregroundStyle(needsAttention ? AnyShapeStyle(.accent) : AnyShapeStyle(.secondary))
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var statusText: some View {
        switch summary {
        case .synced(let date):
            // refreshes so "1 minute ago" doesn't go stale while the screen is open
            TimelineView(.periodic(from: .now, by: 30)) { _ in
                Text("Last synced \(date, format: .relative(presentation: .numeric, unitsStyle: .wide))")
            }
        case .syncing: Text("Syncing…")
        case .waiting: Text("Waiting for the first sync")
        case .offline: Text("Offline – will sync when you're back online")
        case .busy: Text("iCloud is busy – will try again")
        case .noAccount: Text("No iCloud account – changes stay on this device")
        case .storageFull: Text("iCloud storage is full – changes aren't being saved")
        case .problem(let message): Text("Sync problem: \(message)")
        }
    }
}

#Preview("All states") {
    let states: [SyncStatusModel.Summary] = [
        .synced(.now.addingTimeInterval(-180)), .syncing, .waiting, .offline, .busy,
        .noAccount, .storageFull,
        .problem("The operation couldn't be completed. (CKErrorDomain error 15.)")
    ]

    List {
        ForEach(states.indices, id: \.self) { index in
            Section {
                SyncStatusRow(summary: states[index])
            }
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Large text") {
    List {
        Section {
            SyncStatusRow(summary: .offline)
        }
        Section {
            SyncStatusRow(summary: .storageFull)
        }
    }
    .dynamicTypeSize(.accessibility3)
    .preferredColorScheme(.dark)
}
