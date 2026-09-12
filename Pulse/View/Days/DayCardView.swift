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
    
    @Environment(FilterState.self) private var filterState
    @AppStorage(AppStorageKeys.theme) private var themeName: String = "traffic"
    @State private var isPresentingDay: Bool = false
    
    private var sortedAndFilteredMoments: [DailyLogEntry] {
        entry.logEntries?
            .filter( {
                if let selectedTag = filterState.selectedTag, filterState.isFilterActive {
                    return $0.tagsRaw.contains(selectedTag)
                } else {
                    return true
                }
            } )
            .sorted { $0.timestamp < $1.timestamp } ?? []
    }

    private var avgColor: Color {
        var score = entry.averageScore
        
        if let tag = filterState.selectedTag, filterState.isFilterActive {
            let logEntries = entry.logEntries?.filter( { $0.tagsRaw.contains(tag) } ) ?? []
            
            if logEntries.isEmpty {
                score = 0
            } else {
               score = logEntries.reduce(0, { $0 + CGFloat($1.score) } ) / CGFloat(logEntries.count)
            }
        }
        
        return Theme.named(themeName).color(for: Int(score.rounded())).mix(with: .black, by: 0.35)
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
                    let maxDots = 8
                    ForEach(Array(sortedAndFilteredMoments.prefix(maxDots))) { moment in
                        Circle()
                            .fill(Theme.named(themeName).color(for: moment.score))
                            .frame(width: 10, height: 10)
                    }
                    if sortedAndFilteredMoments.count > maxDots {
                        Text("+\(sortedAndFilteredMoments.count - maxDots)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
                ForEach(sortedAndFilteredMoments) { moment in
                    CompactMomentRow(logEntry: moment)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(10)
        .glassEffect(.regular.tint(avgColor.opacity(0.45)).interactive(), in: RoundedRectangle(cornerRadius: 10))
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
