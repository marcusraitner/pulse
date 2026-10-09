//
//  DuplicateEntryMerge.swift
//  Pulse
//
//  Created by Marcus Raitner on 09.10.26.
//

import Foundation
import OSLog
import SwiftData

/// Merges `DailyEntry` duplicates for the same day (from CloudKit sync races) into one
/// and deletes the rest. The survivor per day is the first entry in `mergeOrder`.
func mergeAndPruneDuplicateEntries(
    _ entries: [DailyEntry], context: ModelContext, calendar: Calendar = .current,
    logger: Logger = Logger(subsystem: "de.raitner.pulse", category: "DuplicateEntryMerge")
) {
    let groupedEntries = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }

    for (_, dayEntries) in groupedEntries where dayEntries.count > 1 {
        // every device must pick the same survivor, see `mergeOrder`
        let ordered = dayEntries.sorted { $0.mergeOrder < $1.mergeOrder }
        merge(sources: Array(ordered.dropFirst()), into: ordered[0],
              context: context, logger: logger)
    }
}

private extension DailyEntry {
    /// Picks the survivor of a same-day merge, and the order the others are merged in. Every
    /// device has to get the same answer, otherwise each keeps the entry the other deletes. So it
    /// only uses values that sync, not the query order or `persistentModelID` (local to a device).
    /// More log entries win, so fewer rows have to move.
    var mergeOrder: (Int, String, Int, String, String) {
        (-(logEntries?.count ?? 0),
         logEntries?.map(\.id.uuidString).min() ?? "",
         -(kpiValues?.count ?? 0),
         summary,
         morning)
    }
}

/// Merges each `source` into `target`, then deletes `source`.
private func merge(sources: [DailyEntry], into target: DailyEntry, context: ModelContext, logger: Logger) {
    for source in sources {
        if !source.summary.isEmpty {
            target.summary = [target.summary, source.summary].filter { !$0.isEmpty }.joined(separator: "\n")
        }
        if !source.morning.isEmpty {
            target.morning = [target.morning, source.morning].filter { !$0.isEmpty }.joined(separator: "\n")
        }

        if let logEntries = source.logEntries, !logEntries.isEmpty {
            for logEntry in logEntries {
                logEntry.entry = target
            }

            source.logEntries = nil
        }

        if let kpiValues = source.kpiValues, !kpiValues.isEmpty {
            for kpi in kpiValues {
                if let targetKpi = target.kpiValues?.first(where: { $0.template == kpi.template } ) {
                    // not summed: duplicates that both recorded a metric usually hold the same
                    // reading, and a rating or a duration would be doubled
                    targetKpi.value = max(targetKpi.value, kpi.value)
                    context.delete(kpi)  // merged into targetKpi; otherwise never cascade-deleted
                } else {
                    kpi.entry = target
                }
            }

            source.kpiValues = nil
        }

        context.delete(source)
        context.saveOrLog("Failed to save after merge", logger: logger)
    }
}
