//
//  PulseTests.swift
//  PulseTests
//
//  Created by Marcus Raitner on 25.03.26.
//

import Testing
import SwiftData
import CoreGraphics
@testable import Pulse
internal import Foundation

// MARK: - Helpers

private func makeContext() throws -> ModelContext {
    let schema = Schema([DailyEntry.self, DailyLogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: config)
    return ModelContext(container)
}

private func makeEntry(scores: [Int], in context: ModelContext) -> DailyEntry {
    let logs = scores.map { DailyLogEntry(timestamp: .now, log: "test", score: $0) }
    let entry = DailyEntry(date: .now, logEntries: logs)
    context.insert(entry)
    return entry
}

// MARK: - DailyEntry.averageScore

@Suite("DailyEntry.averageScore")
struct AverageScoreTests {

    @Test("Returns 0 for empty logEntries")
    func emptyEntries() throws {
        let context = try makeContext()
        let entry = makeEntry(scores: [], in: context)
        #expect(entry.averageScore == 0.0)
    }

    @Test("Returns 0 for nil logEntries")
    func nilEntries() throws {
        let context = try makeContext()
        let entry = DailyEntry(date: .now)
        entry.logEntries = nil
        context.insert(entry)
        #expect(entry.averageScore == 0.0)
    }

    @Test("Returns the score of a single entry")
    func singleEntry() throws {
        let context = try makeContext()
        let entry = makeEntry(scores: [2], in: context)
        #expect(entry.averageScore == 2.0)
    }

    @Test("Returns exact mean for symmetric scores")
    func symmetricScores() throws {
        let context = try makeContext()
        let entry = makeEntry(scores: [2, -2], in: context)
        #expect(entry.averageScore == 0.0)
    }

    @Test("Returns correct mean for mixed scores")
    func mixedScores() throws {
        let context = try makeContext()
        // (2 + -2 + 1) / 3 = 1/3
        let entry = makeEntry(scores: [2, -2, 1], in: context)
        #expect(abs(entry.averageScore - CGFloat(1) / CGFloat(3)) < 0.001)
    }

    @Test("Returns correct mean for all-positive scores")
    func allPositive() throws {
        let context = try makeContext()
        // (1 + 2 + 1) / 3 = 1.333…
        let entry = makeEntry(scores: [1, 2, 1], in: context)
        #expect(abs(entry.averageScore - CGFloat(4) / CGFloat(3)) < 0.001)
    }

    @Test("Returns correct mean for all-negative scores")
    func allNegative() throws {
        let context = try makeContext()
        // (-1 + -2) / 2 = -1.5
        let entry = makeEntry(scores: [-1, -2], in: context)
        #expect(entry.averageScore == -1.5)
    }
}

// MARK: - DailyEntry cascade deletion

@Suite("DailyEntry cascade deletion")
struct CascadeDeletionTests {

    @Test("Deleting a DailyEntry removes all its DailyLogEntries")
    func deletingEntryDeletesLogEntries() throws {
        let context = try makeContext()

        let entry = makeEntry(scores: [2, 1, -1], in: context)
        try context.save()

        // Confirm children exist before deletion
        let logsBefore = try context.fetch(FetchDescriptor<DailyLogEntry>())
        #expect(logsBefore.count == 3)

        context.delete(entry)
        try context.save()

        let logsAfter = try context.fetch(FetchDescriptor<DailyLogEntry>())
        #expect(logsAfter.isEmpty)
    }

    @Test("Deleting one DailyEntry leaves sibling entries untouched")
    func deletingOneEntryLeavesOthersIntact() throws {
        let context = try makeContext()

        let entryA = makeEntry(scores: [2, 1], in: context)
        let _ = makeEntry(scores: [-1], in: context)
        try context.save()

        context.delete(entryA)
        try context.save()

        let remainingEntries = try context.fetch(FetchDescriptor<DailyEntry>())
        #expect(remainingEntries.count == 1)
        #expect(remainingEntries.first?.logEntries?.count == 1)

        let remainingLogs = try context.fetch(FetchDescriptor<DailyLogEntry>())
        #expect(remainingLogs.count == 1)
    }

    @Test("Deleting a DailyEntry with no log entries succeeds")
    func deletingEmptyEntry() throws {
        let context = try makeContext()

        let entry = makeEntry(scores: [], in: context)
        try context.save()

        context.delete(entry)
        #expect(throws: Never.self) { try context.save() }

        let remaining = try context.fetch(FetchDescriptor<DailyEntry>())
        #expect(remaining.isEmpty)
    }
}

// MARK: - Export payload mapping

@Suite("ExportPayloadMapper")
struct ExportPayloadMapperTests {
    @Test("Maps and sorts entries, logs, KPI values, and templates")
    func mapsAndSortsPayloadData() {
        let templateB = KPITemplate(title: "Exercise", unit: "min", sortOrder: 2)
        let templateA = KPITemplate(title: "Deep Work", note: "Focus time", unit: "h", sortOrder: 1)

        let baseDate = Date(timeIntervalSince1970: 1_750_000_000)
        let logLater = DailyLogEntry(timestamp: baseDate.addingTimeInterval(3_600), log: "Later", score: 1)
        let logEarlier = DailyLogEntry(
            timestamp: baseDate,
            log: "Earlier",
            score: 2,
            latitude: 48.137_154,
            longitude: 11.576_124,
            address: "Munich",
            tagsRaw: "deep work,focus"
        )

        let earlierEntry = DailyEntry(
            date: baseDate,
            summary: "Earlier day",
            logEntries: [logLater, logEarlier]
        )
        let laterEntry = DailyEntry(
            date: baseDate.addingTimeInterval(86_400),
            summary: "Later day",
            logEntries: []
        )

        let valueForTemplateB = DailyKPIValue(value: 10, template: templateB, entry: earlierEntry)
        let valueForTemplateA = DailyKPIValue(value: 4, template: templateA, entry: earlierEntry)
        earlierEntry.kpiValues = [valueForTemplateB, valueForTemplateA]
        laterEntry.kpiValues = []

        let payload = ExportPayloadMapper.exportPayload(
            from: [laterEntry, earlierEntry],
            kpiTemplates: [templateB, templateA]
        )

        #expect(payload.modelSchemaVersion == ExportPayloadMapper.currentModelSchemaVersion)
        #expect(payload.formatVersion == ExportPayloadMapper.currentFormatVersion)
        #expect(payload.entries.map(\.summary) == ["Earlier day", "Later day"])
        #expect(payload.kpiTemplates.map(\.id) == [templateA.id, templateB.id])

        let exportedEarlierEntry = payload.entries[0]
        #expect(exportedEarlierEntry.logEntries.count == 2)
        #expect(exportedEarlierEntry.logEntries.map(\.timestamp) == [logEarlier.timestamp, logLater.timestamp])

        #expect(exportedEarlierEntry.logEntries[0].latitude == logEarlier.latitude)
        #expect(exportedEarlierEntry.logEntries[0].longitude == logEarlier.longitude)
        #expect(exportedEarlierEntry.logEntries[0].address == logEarlier.address)
        #expect(exportedEarlierEntry.logEntries[0].tagsRaw == logEarlier.tagsRaw)

        #expect(exportedEarlierEntry.kpiValues.count == 2)
        #expect(exportedEarlierEntry.kpiValues.map(\.templateID) == [templateA.id, templateB.id])
    }

    @MainActor
    @Test("Encoded payload contains export contract keys")
    func encodedPayloadContainsExpectedKeys() throws {
        let template = KPITemplate(title: "Sleep", unit: "h", sortOrder: 1)
        let logEntry = DailyLogEntry(
            timestamp: Date(timeIntervalSince1970: 1_750_000_100),
            log: "Checked in",
            score: 1,
            tagsRaw: "sleep,recovery"
        )
        let entry = DailyEntry(
            date: Date(timeIntervalSince1970: 1_750_000_000),
            summary: "Summary",
            logEntries: [logEntry]
        )
        entry.kpiValues = [DailyKPIValue(value: 7, template: template, entry: entry)]

        let payload = ExportPayloadMapper.exportPayload(from: [entry], kpiTemplates: [template])

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"formatVersion\""))
        #expect(json.contains("\"modelSchemaVersion\""))
        #expect(json.contains("\"entries\""))
        #expect(json.contains("\"kpiTemplates\""))
        #expect(json.contains("\"templateID\""))
        #expect(json.contains("\"tagsRaw\""))
    }
}


// MARK: - missingEntryDates

@Suite("missingEntryDates")
struct MissingEntryDatesTests {

    private static func calendar(_ identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }

    private let berlin = calendar("Europe/Berlin")

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0,
                     _ calendar: Calendar? = nil) -> Date {
        (calendar ?? berlin).date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test("Fills the gap, newest first, start excluded")
    func fillsGap() {
        let missing = missingEntryDates(existing: [day(2026, 3, 1), day(2026, 3, 5)],
                                        from: day(2026, 3, 1), to: day(2026, 3, 5), calendar: berlin)
        #expect(missing == [day(2026, 3, 4), day(2026, 3, 3), day(2026, 3, 2)])
    }

    @Test("Returns nothing when every day exists")
    func idempotent() {
        let all = (1...5).map { day(2026, 3, $0) }
        #expect(missingEntryDates(existing: all, from: all[0], to: all[4], calendar: berlin).isEmpty)
    }

    @Test("Includes end when today is missing")
    func endMissing() {
        let missing = missingEntryDates(existing: [day(2026, 3, 1), day(2026, 3, 2)],
                                        from: day(2026, 3, 1), to: day(2026, 3, 4), calendar: berlin)
        #expect(missing == [day(2026, 3, 4), day(2026, 3, 3)])
    }

    @Test("Ignores the time of day of existing entries")
    func timeOfDayIrrelevant() {
        let missing = missingEntryDates(existing: [day(2026, 3, 1, hour: 9), day(2026, 3, 3, hour: 23)],
                                        from: day(2026, 3, 1, hour: 9), to: day(2026, 3, 3, hour: 23),
                                        calendar: berlin)
        #expect(missing == [day(2026, 3, 2)])
    }

    @Test("Tail path fills a multi-day gap without mapping the history")
    func tailFillsLongGap() {
        // app not opened since 3 March, reopened on 12 April
        let newest = day(2026, 3, 3, hour: 21)
        let today = day(2026, 4, 12, hour: 8)

        let tail = missingEntryDates(existing: [newest], from: newest, to: today, calendar: berlin)
        let history = (1...3).map { day(2026, 3, $0, hour: 21) }
        let sweep = missingEntryDates(existing: history, from: history[0], to: today, calendar: berlin)

        #expect(tail.count == 40)
        #expect(tail.first == day(2026, 4, 12))
        #expect(tail.last == day(2026, 3, 4))
        #expect(tail == sweep)  // the shortcut must not change the result
    }

    // Santiago has no 00:00 on 2024-09-08; unnormalised day arithmetic drifts to 01:00
    // and the next sweep inserts those days a second time.
    @Test("Stays on day boundaries across a midnight DST shift")
    func dstShiftAtMidnight() {
        let santiago = Self.calendar("America/Santiago")
        let missing = missingEntryDates(existing: [day(2024, 9, 5, hour: 12, santiago)],
                                        from: day(2024, 9, 5, hour: 12, santiago),
                                        to: day(2024, 9, 10, hour: 12, santiago), calendar: santiago)
        #expect(missing.count == 5)
        #expect(Set(missing).count == 5)
        #expect(missing.allSatisfy { santiago.startOfDay(for: $0) == $0 })
    }
}
