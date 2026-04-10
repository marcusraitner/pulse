//
//  DayCardView.swift
//  Pulse
//
//  Created by Marcus Raitner on 05.04.26.
//

import SwiftData
import SwiftUI

/// A compact glass card representing a single day: a date header and its log moments.
/// Designed to be reused as a building block inside the week view.
///
/// - `date` is always required (so the card can be shown even for days with no entry).
/// - `entry` is optional; when `nil` the card shows only the date header.
struct DayCardView: View {
    let date: Date
    let entry: DailyEntry

    @AppStorage(AppStorageKeys.theme) private var themeName: String = "traffic"
    @State private var isPresentingDay: Bool = false
    
    private var sortedMoments: [DailyLogEntry] {
        entry.logEntries?.sorted { $0.timestamp < $1.timestamp } ?? []
    }

    private var avgColor: Color {
        Theme.named(themeName).color(for: Int(entry.averageScore.rounded()))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Day header
            HStack(spacing: 6) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .bold()
                Text(date.formatted(.dateTime.day().month()))
                Spacer()
            }
            .font(.caption)

            // Compact moment rows
            ForEach(sortedMoments) { moment in
                CompactMomentRow(logEntry: moment)
                    .contentShape(Rectangle())
            }
        }
        .padding(10)
        .glassTintedCard(color: avgColor)
        .contentShape(Rectangle())
        .onTapGesture {
            isPresentingDay = true
        }
        .sheet(isPresented: $isPresentingDay) {
            NavigationStack {
                DailyReflectionSheet(day: entry)
            }
        }
    }
}

// MARK: - CompactMomentRow

/// A single-line row showing a score color strip, truncated log text, and a timestamp.
private struct CompactMomentRow: View {
    let logEntry: DailyLogEntry
    @AppStorage(AppStorageKeys.theme) private var themeName: String = "traffic"

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Theme.named(themeName).color(for: logEntry.score))
                .frame(width: 8, height: 8)

            Text(logEntry.log)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.white.opacity(0.9))

            Spacer(minLength: 4)

            Text(logEntry.formattedTimestamp)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .fixedSize()
        }
    }
}

// MARK: - Previews

private struct DayCardPreviewContainer: View {
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries: [DailyEntry]

    var body: some View {
        if let entry = entries.first {
            DayCardView(date: entry.date, entry: entry)
                .padding()
                .background(.black)
        } else {
            Text("No sample data")
        }
    }
}

#Preview("With moments") {
    DayCardPreviewContainer()
        .modelContainer(SampleData.shared.modelContainer)
}

#Preview("Entry, no moments") {
    DayCardView(date: .now, entry: DailyEntry(date: .now))
        .padding()
        .background(.black)
}
