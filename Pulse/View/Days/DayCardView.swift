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
/// - `entry` The entry to display in this card.
struct DayCardView: View {
    let entry: DailyEntry
    let aggregationLevel: AggregationLevel

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
                Text(entry.date.formatted(.dateTime.weekday(.abbreviated)))
                    .bold()
                Text(entry.date.formatted(.dateTime.day().month()))
                Spacer()
                if aggregationLevel == .month {
                    ForEach(sortedMoments) { moment in
                        Circle()
                            .fill(Theme.named(themeName).color(for: moment.score))
                            .frame(width: 10, height: 10)
                    }
                }
            }
            
            if !entry.summary.isEmpty {
                Text(entry.summary)
                    .lineLimit(2)
                    .padding(.vertical, 4)
            }

            if aggregationLevel == .week {
                // Compact moment rows
                ForEach(sortedMoments) { moment in
                    CompactMomentRow(logEntry: moment)
                        .contentShape(Rectangle())
                }
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
                .frame(width: 10, height: 10)

            Text(logEntry.log)
                .font(.footnote)
                .lineLimit(1)
                .foregroundStyle(.primary)

            Spacer(minLength: 4)

            Text(logEntry.formattedTimestamp)
                .font(.footnote)
                .foregroundStyle(.primary.opacity(0.5))
                .fixedSize()
        }
    }
}

// MARK: - Previews

private struct DayCardPreviewContainer: View {
    let aggregationLevel: AggregationLevel
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries: [DailyEntry]

    var body: some View {
        if let entry = entries.first {
            DayCardView(entry: entry, aggregationLevel: aggregationLevel)
                .padding()
                .background(.black)
        } else {
            Text("No sample data")
        }
    }
}

#Preview("Week Level") {
    DayCardPreviewContainer(aggregationLevel: .week)
        .modelContainer(SampleData.shared.modelContainer)
}

#Preview("Month Level") {
    DayCardPreviewContainer(aggregationLevel: .month)
        .modelContainer(SampleData.shared.modelContainer)
}
