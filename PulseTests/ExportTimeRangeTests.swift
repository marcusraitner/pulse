//
//  ExportTimeRangeTests.swift
//  PulseTests
//
//  Created by Marcus Raitner on 03.10.26.
//

import Testing
@testable import Pulse
internal import Foundation

// MARK: - ExportTimeRange.dateRange
//
// Reference "now": Wednesday 7 Oct 2026, 14:30. Weeks start on Monday (ISO) or
// Sunday (US) depending on the calendar, so each week test runs for both.

@Suite("ExportTimeRange.dateRange")
struct ExportTimeRangeTests {

    private static func calendar(_ identifier: String, firstWeekday: Int = 2) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        calendar.firstWeekday = firstWeekday  // 1 = Sunday, 2 = Monday
        return calendar
    }

    private let monday = calendar("Europe/Berlin", firstWeekday: 2)
    private let sunday = calendar("Europe/Berlin", firstWeekday: 1)

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0,
                      _ second: Int = 0, in calendar: Calendar? = nil) -> Date {
        (calendar ?? monday).date(from: DateComponents(year: year, month: month, day: day,
                                                       hour: hour, minute: minute, second: second))!
    }

    /// 23:59:59 of the given day, matching the existing custom-range behavior.
    private func endOfDay(_ year: Int, _ month: Int, _ day: Int, in calendar: Calendar? = nil) -> Date {
        date(year, month, day, 23, 59, 59, in: calendar)
    }

    private func range(_ preset: ExportTimeRange, now: Date, calendar: Calendar? = nil,
                       from: Date? = nil, to: Date? = nil) -> ClosedRange<Date>? {
        preset.dateRange(now: now, calendar: calendar ?? monday,
                         customFrom: from ?? now, customTo: to ?? now)
    }

    private var now: Date { date(2026, 10, 7, 14, 30) }

    // MARK: Cases

    @Test("Offers the presets in picker order")
    func allCases() {
        #expect(ExportTimeRange.allCases == [
            .allTime, .last7Days, .last30Days, .thisWeek, .lastWeek, .thisMonth, .lastMonth, .custom,
        ])
    }

    // MARK: All time

    @Test("All time applies no restriction")
    func allTime() {
        #expect(range(.allTime, now: now) == nil)
    }

    // MARK: Rolling ranges

    @Test("Last 7 days is today plus the previous six days")
    func last7Days() {
        #expect(range(.last7Days, now: now) == date(2026, 10, 1)...endOfDay(2026, 10, 7))
    }

    @Test("Last 30 days is today plus the previous 29 days")
    func last30Days() {
        #expect(range(.last30Days, now: now) == date(2026, 9, 8)...endOfDay(2026, 10, 7))
    }

    @Test("Rolling ranges cover exactly N calendar days")
    func rollingLength() throws {
        for (preset, days) in [(ExportTimeRange.last7Days, 7), (.last30Days, 30)] {
            let r = try #require(range(preset, now: now))
            let span = monday.dateComponents([.day], from: r.lowerBound,
                                             to: r.upperBound.addingTimeInterval(1)).day
            #expect(span == days)
        }
    }

    @Test("Last 7 days rolls back across a year boundary")
    func last7DaysYearRollover() {
        let newYear = date(2026, 1, 3, 9)
        #expect(range(.last7Days, now: newYear) == date(2025, 12, 28)...endOfDay(2026, 1, 3))
    }

    @Test("Rolling ranges count calendar days across a 25-hour DST day")
    func last7DaysAcrossDSTEnd() {
        // Europe/Berlin leaves DST on 25 Oct 2026; 7 * 86400 s would land on 23:00 of the previous day
        let afterShift = date(2026, 10, 26, 12)
        #expect(range(.last7Days, now: afterShift) == date(2026, 10, 20)...endOfDay(2026, 10, 26))
    }

    @Test("Rolling ranges start on a day boundary where midnight does not exist")
    func last7DaysAtMissingMidnight() throws {
        // Santiago has no 00:00 on 2024-09-08; startOfDay lands on 01:00
        let santiago = Self.calendar("America/Santiago")
        let now = date(2024, 9, 10, 12, in: santiago)
        let r = try #require(range(.last7Days, now: now, calendar: santiago))
        #expect(r.lowerBound == santiago.startOfDay(for: date(2024, 9, 4, in: santiago)))
        #expect(santiago.startOfDay(for: r.upperBound) == santiago.startOfDay(for: now))
    }

    // MARK: Weeks

    @Test("This week runs from the week start through today (Monday start)")
    func thisWeekMonday() {
        #expect(range(.thisWeek, now: now) == date(2026, 10, 5)...endOfDay(2026, 10, 7))
    }

    @Test("This week runs from the week start through today (Sunday start)")
    func thisWeekSunday() {
        #expect(range(.thisWeek, now: now, calendar: sunday)
                == date(2026, 10, 4, in: sunday)...endOfDay(2026, 10, 7, in: sunday))
    }

    @Test("This week on the first day of the week covers just that day")
    func thisWeekOnFirstDay() {
        let firstDay = date(2026, 10, 5, 8)  // Monday
        #expect(range(.thisWeek, now: firstDay) == date(2026, 10, 5)...endOfDay(2026, 10, 5))
    }

    @Test("Last week is the complete previous week (Monday start)")
    func lastWeekMonday() {
        #expect(range(.lastWeek, now: now) == date(2026, 9, 28)...endOfDay(2026, 10, 4))
    }

    @Test("Last week is the complete previous week (Sunday start)")
    func lastWeekSunday() {
        #expect(range(.lastWeek, now: now, calendar: sunday)
                == date(2026, 9, 27, in: sunday)...endOfDay(2026, 10, 3, in: sunday))
    }

    @Test("Last week reaches into the previous year at New Year")
    func lastWeekYearRollover() {
        // Thu 1 Jan 2026: this week starts Mon 29 Dec 2025, so last week is 22–28 Dec 2025
        let newYear = date(2026, 1, 1, 10)
        #expect(range(.lastWeek, now: newYear) == date(2025, 12, 22)...endOfDay(2025, 12, 28))
    }

    @Test("This week reaches into the previous year at New Year")
    func thisWeekYearRollover() {
        let newYear = date(2026, 1, 1, 10)
        #expect(range(.thisWeek, now: newYear) == date(2025, 12, 29)...endOfDay(2026, 1, 1))
    }

    // MARK: Months

    @Test("This month runs from the first through today")
    func thisMonth() {
        #expect(range(.thisMonth, now: now) == date(2026, 10, 1)...endOfDay(2026, 10, 7))
    }

    @Test("This month on the 1st covers just that day")
    func thisMonthOnFirst() {
        #expect(range(.thisMonth, now: date(2026, 10, 1, 7)) == date(2026, 10, 1)...endOfDay(2026, 10, 1))
    }

    @Test("Last month is the complete previous month")
    func lastMonth() {
        #expect(range(.lastMonth, now: now) == date(2026, 9, 1)...endOfDay(2026, 9, 30))
    }

    @Test("Last month in January is December of the previous year")
    func lastMonthYearRollover() {
        #expect(range(.lastMonth, now: date(2026, 1, 15, 12)) == date(2025, 12, 1)...endOfDay(2025, 12, 31))
    }

    @Test("Last month handles a leap-year February")
    func lastMonthLeapFebruary() {
        #expect(range(.lastMonth, now: date(2024, 3, 10, 12)) == date(2024, 2, 1)...endOfDay(2024, 2, 29))
    }

    @Test("Last month is unaffected by the current month being longer")
    func lastMonthShortPrevious() {
        // 31 March -> February; naive "minus one month" arithmetic would hit an invalid date
        #expect(range(.lastMonth, now: date(2026, 3, 31, 12)) == date(2026, 2, 1)...endOfDay(2026, 2, 28))
    }

    // MARK: Boundaries

    @Test("Boundaries are inclusive at day granularity")
    func inclusiveBoundaries() throws {
        let r = try #require(range(.lastMonth, now: now))
        #expect(r.contains(date(2026, 9, 1)))
        #expect(r.contains(date(2026, 9, 1, 0, 0, 1)))
        #expect(r.contains(date(2026, 9, 30, 23, 59)))
        #expect(!r.contains(date(2026, 8, 31, 23, 59, 59)))
        #expect(!r.contains(date(2026, 10, 1)))
    }

    @Test("The time of day of now does not change the range")
    func timeOfDayIrrelevant() {
        let early = range(.thisWeek, now: date(2026, 10, 7, 0, 0, 1))
        let late = range(.thisWeek, now: date(2026, 10, 7, 23, 59, 59))
        #expect(early == late)
        #expect(early != nil)
    }

    // MARK: Custom

    @Test("Custom spans the start of the From day to the end of the To day")
    func customRange() {
        let r = range(.custom, now: now, from: date(2026, 8, 3, 15), to: date(2026, 8, 9, 6))
        #expect(r == date(2026, 8, 3)...endOfDay(2026, 8, 9))
    }

    @Test("Custom with From after To swaps the bounds")
    func customReversed() {
        let r = range(.custom, now: now, from: date(2026, 8, 9, 6), to: date(2026, 8, 3, 15))
        #expect(r == date(2026, 8, 3)...endOfDay(2026, 8, 9))
    }

    @Test("Custom with the same day twice covers that whole day")
    func customSingleDay() {
        let r = range(.custom, now: now, from: date(2026, 8, 3, 12), to: date(2026, 8, 3, 12))
        #expect(r == date(2026, 8, 3)...endOfDay(2026, 8, 3))
    }

    @Test("Presets ignore the custom dates")
    func presetsIgnoreCustom() {
        let custom = (from: date(2020, 1, 1), to: date(2020, 1, 31))
        for preset in ExportTimeRange.allCases where preset != .custom {
            #expect(range(preset, now: now, from: custom.from, to: custom.to)
                    == range(preset, now: now))
        }
    }
}
