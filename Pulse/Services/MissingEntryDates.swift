//
//  MissingEntryDates.swift
//  Pulse
//
//  Created by Marcus Raitner on 09.10.26.
//

import Foundation

/// Day-starts between `start` and `end` that have no entry yet, newest first.
/// `start` itself is excluded — it already exists.
func missingEntryDates(existing: [Date], from start: Date, to end: Date,
                       calendar: Calendar = .current) -> [Date] {
    let have = Set(existing.map { calendar.startOfDay(for: $0) })
    let firstDay = calendar.startOfDay(for: start)
    var missing: [Date] = []
    var current = calendar.startOfDay(for: end)

    while current > firstDay {
        if !have.contains(current) { missing.append(current) }

        guard let previous = calendar.date(byAdding: .day, value: -1, to: current) else { break }
        // re-normalise: day arithmetic lands off midnight where DST shifts at 00:00
        let previousDay = calendar.startOfDay(for: previous)
        guard previousDay < current else { break }  // ponytail: paranoia, no hang if it ever stalls
        current = previousDay
    }

    return missing
}
