//
//  ExportTimeRange.swift
//  Pulse
//
//  Created by Marcus Raitner on 03.10.26.
//

import SwiftUI

/// Preset periods for restricting the JSON export.
enum ExportTimeRange: CaseIterable {
    case allTime, last7Days, last30Days, thisWeek, lastWeek, thisMonth, lastMonth, custom

    var label: LocalizedStringKey {
        switch self {
        case .allTime: "All time"
        case .last7Days: "Last 7 days"
        case .last30Days: "Last 30 days"
        case .thisWeek: "This week"
        case .lastWeek: "Last week"
        case .thisMonth: "This month"
        case .lastMonth: "Last month"
        case .custom: "Custom range"
        }
    }

    /// The export range for this preset, from the start of its first day to 23:59:59 of its last day.
    /// `nil` means no restriction. `customFrom`/`customTo` only matter for `.custom`, where their
    /// order is irrelevant. Resolve at export time so the range never goes stale.
    func dateRange(now: Date, calendar: Calendar, customFrom: Date, customTo: Date) -> ClosedRange<Date>? {
        let today = calendar.startOfDay(for: now)

        switch self {
        case .allTime:
            return nil
        case .last7Days:
            return range(from: today, daysBack: 6, until: today, in: calendar)
        case .last30Days:
            return range(from: today, daysBack: 29, until: today, in: calendar)
        case .thisWeek:
            return calendar.dateInterval(of: .weekOfYear, for: now)
                .flatMap { range(start: $0.start, lastDay: today, in: calendar) }
        case .lastWeek:
            return previousPeriod(of: .weekOfYear, component: .weekOfYear, for: now, in: calendar)
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)
                .flatMap { range(start: $0.start, lastDay: today, in: calendar) }
        case .lastMonth:
            return previousPeriod(of: .month, component: .month, for: now, in: calendar)
        case .custom:
            return range(start: calendar.startOfDay(for: min(customFrom, customTo)),
                         lastDay: max(customFrom, customTo), in: calendar)
        }
    }

    private func range(from day: Date, daysBack: Int, until lastDay: Date, in calendar: Calendar) -> ClosedRange<Date>? {
        // calendar-day arithmetic, not seconds, so DST days of 23/25 hours stay correct
        calendar.date(byAdding: .day, value: -daysBack, to: day)
            .flatMap { range(start: calendar.startOfDay(for: $0), lastDay: lastDay, in: calendar) }
    }

    /// The complete period before the one containing `date`.
    private func previousPeriod(of interval: Calendar.Component, component: Calendar.Component,
                                for date: Date, in calendar: Calendar) -> ClosedRange<Date>? {
        guard let current = calendar.dateInterval(of: interval, for: date),
              let previous = calendar.date(byAdding: component, value: -1, to: current.start)
        else { return nil }

        // the second before the current period starts is 23:59:59 of the previous period's last day
        return calendar.startOfDay(for: previous)...current.start.addingTimeInterval(-1)
    }

    private func range(start: Date, lastDay: Date, in calendar: Calendar) -> ClosedRange<Date>? {
        calendar.date(byAdding: DateComponents(day: 1, second: -1), to: calendar.startOfDay(for: lastDay))
            .map { start...$0 }
    }
}
