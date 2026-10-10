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
    let schema = Schema([DailyEntry.self, DailyLogEntry.self, DailyKPIValue.self, KPITemplate.self])
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

    @Test("Returns nil for empty logEntries")
    func emptyEntries() throws {
        let context = try makeContext()
        let entry = makeEntry(scores: [], in: context)
        #expect(entry.averageScore == nil)
    }

    @Test("Returns nil for nil logEntries")
    func nilEntries() throws {
        let context = try makeContext()
        let entry = DailyEntry(date: .now)
        entry.logEntries = nil
        context.insert(entry)
        #expect(entry.averageScore == nil)
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
        #expect(abs(try #require(entry.averageScore) - CGFloat(1) / CGFloat(3)) < 0.001)
    }

    @Test("Returns correct mean for all-positive scores")
    func allPositive() throws {
        let context = try makeContext()
        // (1 + 2 + 1) / 3 = 1.333…
        let entry = makeEntry(scores: [1, 2, 1], in: context)
        #expect(abs(try #require(entry.averageScore) - CGFloat(4) / CGFloat(3)) < 0.001)
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


// MARK: - mergeAndPruneDuplicateEntries

@Suite("mergeAndPruneDuplicateEntries")
struct MergeAndPruneDuplicateEntriesTests {

    @Test("Leaves entries on distinct days untouched")
    func noDuplicates() throws {
        let context = try makeContext()
        let day1 = DailyEntry(date: Date(timeIntervalSince1970: 0), summary: "one")
        let day2 = DailyEntry(date: Date(timeIntervalSince1970: 86_400), summary: "two")
        context.insert(day1)
        context.insert(day2)

        mergeAndPruneDuplicateEntries([day1, day2], context: context)

        #expect(try context.fetch(FetchDescriptor<DailyEntry>()).count == 2)
    }

    @Test("Concatenates summary and morning with a newline, in merge order")
    func mergesTextFields() throws {
        let context = try makeContext()
        let a = DailyEntry(date: Date(timeIntervalSince1970: 0), summary: "Went well", morning: "Slept ok")
        let b = DailyEntry(date: Date(timeIntervalSince1970: 0), summary: "Also good", morning: "Woke early")
        context.insert(a)
        context.insert(b)

        mergeAndPruneDuplicateEntries([a, b], context: context)

        // "Also good" sorts first, so `b` survives and `a` is merged into it
        let merged = try #require(context.fetch(FetchDescriptor<DailyEntry>()).first)
        #expect(merged.summary == "Also good\nWent well")
        #expect(merged.morning == "Woke early\nSlept ok")
        #expect(try context.fetch(FetchDescriptor<DailyEntry>()).count == 1)
    }

    @Test("Skips an empty duplicate field instead of leaving a stray newline")
    func skipsEmptyTextFields() throws {
        let context = try makeContext()
        let a = DailyEntry(date: Date(timeIntervalSince1970: 0), summary: "Went well")
        let b = DailyEntry(date: Date(timeIntervalSince1970: 0), summary: "")
        context.insert(a)
        context.insert(b)

        mergeAndPruneDuplicateEntries([a, b], context: context)

        let merged = try #require(context.fetch(FetchDescriptor<DailyEntry>()).first)
        #expect(merged.summary == "Went well")
    }

    @Test("Reassigns duplicate's log entries to the survivor and deletes the duplicate")
    func reassignsLogEntries() throws {
        let context = try makeContext()
        let logA = DailyLogEntry(timestamp: .now, log: "a", score: 1)
        let logB = DailyLogEntry(timestamp: .now, log: "b", score: 2)
        let a = DailyEntry(date: Date(timeIntervalSince1970: 0), logEntries: [logA])
        let b = DailyEntry(date: Date(timeIntervalSince1970: 0), logEntries: [logB])
        context.insert(a)
        context.insert(b)
        try context.save()

        mergeAndPruneDuplicateEntries([a, b], context: context)

        let merged = try #require(context.fetch(FetchDescriptor<DailyEntry>()).first)
        #expect(Set(merged.logEntries?.map(\.log) ?? []) == ["a", "b"])
        #expect(try context.fetch(FetchDescriptor<DailyEntry>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<DailyLogEntry>()).count == 2)
    }

    @Test("Keeps the larger KPI value for a shared template and deletes the redundant row",
          arguments: zip([100, 50], [50, 100]))
    func keepsLargerKPIValue(first: Int, second: Int) throws {
        let context = try makeContext()
        let template = KPITemplate(title: "Steps")
        context.insert(template)

        let a = DailyEntry(date: Date(timeIntervalSince1970: 0))
        let b = DailyEntry(date: Date(timeIntervalSince1970: 0))
        context.insert(a)
        context.insert(b)

        a.kpiValues = [DailyKPIValue(value: first, template: template, entry: a)]
        b.kpiValues = [DailyKPIValue(value: second, template: template, entry: b)]
        try context.save()

        mergeAndPruneDuplicateEntries([a, b], context: context)

        // the two entries tie, so either may survive; the larger value must win either way
        let merged = try #require(context.fetch(FetchDescriptor<DailyEntry>()).first)
        #expect(merged.kpiValues?.map(\.value) == [100])
        // the merged-away duplicate's KPI row must not linger as an orphan
        #expect(try context.fetch(FetchDescriptor<DailyKPIValue>()).count == 1)
    }

    @Test("Keeps KPI values for templates the survivor doesn't have yet")
    func movesNonMatchingKPITemplate() throws {
        let context = try makeContext()
        let steps = KPITemplate(title: "Steps")
        let sleep = KPITemplate(title: "Sleep")
        context.insert(steps)
        context.insert(sleep)

        let a = DailyEntry(date: Date(timeIntervalSince1970: 0))
        let b = DailyEntry(date: Date(timeIntervalSince1970: 0))
        context.insert(a)
        context.insert(b)

        a.kpiValues = [DailyKPIValue(value: 100, template: steps, entry: a)]
        b.kpiValues = [DailyKPIValue(value: 8, template: sleep, entry: b)]
        try context.save()

        mergeAndPruneDuplicateEntries([a, b], context: context)

        let merged = try #require(context.fetch(FetchDescriptor<DailyEntry>()).first)
        #expect(Set(merged.kpiValues?.map(\.template?.title) ?? []) == ["Steps", "Sleep"])
        #expect(try context.fetch(FetchDescriptor<DailyKPIValue>()).count == 2)
    }

    @Test("Picks the same survivor whatever order the entries arrive in", arguments: [false, true])
    func survivorIgnoresInputOrder(reversed: Bool) throws {
        let context = try makeContext()
        // identical but for the log ids, so the lowest id has to decide
        let lowLog = DailyLogEntry(timestamp: .now, log: "low", score: 1)
        lowLog.id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        let highLog = DailyLogEntry(timestamp: .now, log: "high", score: 1)
        highLog.id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))

        let low = DailyEntry(date: Date(timeIntervalSince1970: 0), logEntries: [lowLog])
        let high = DailyEntry(date: Date(timeIntervalSince1970: 0), logEntries: [highLog])
        context.insert(low)
        context.insert(high)

        mergeAndPruneDuplicateEntries(reversed ? [high, low] : [low, high], context: context)

        let remaining = try context.fetch(FetchDescriptor<DailyEntry>())
        #expect(remaining.count == 1)
        #expect(remaining.first === low)
    }

    @Test("Concatenates text in the same order whatever order the entries arrive in",
          arguments: [false, true])
    func textOrderIgnoresInputOrder(reversed: Bool) throws {
        let context = try makeContext()
        let x = DailyEntry(date: Date(timeIntervalSince1970: 0), summary: "x")
        let y = DailyEntry(date: Date(timeIntervalSince1970: 0), summary: "y")
        context.insert(x)
        context.insert(y)

        mergeAndPruneDuplicateEntries(reversed ? [y, x] : [x, y], context: context)

        let merged = try #require(context.fetch(FetchDescriptor<DailyEntry>()).first)
        #expect(merged.summary == "x\ny")
    }

    @Test("The entry with more log entries survives, so fewer rows move")
    func entryWithMoreLogsSurvives() throws {
        let context = try makeContext()
        // the single log has the lower id, so only the log count can make `busy` win
        let singleLog = DailyLogEntry(timestamp: .now, log: "single", score: 1)
        singleLog.id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        let busyLogs = [
            DailyLogEntry(timestamp: .now, log: "one", score: 1),
            DailyLogEntry(timestamp: .now, log: "two", score: 1),
        ]

        let quiet = DailyEntry(date: Date(timeIntervalSince1970: 0), logEntries: [singleLog])
        let busy = DailyEntry(date: Date(timeIntervalSince1970: 0), logEntries: busyLogs)
        context.insert(quiet)
        context.insert(busy)

        mergeAndPruneDuplicateEntries([quiet, busy], context: context)

        let remaining = try context.fetch(FetchDescriptor<DailyEntry>())
        #expect(remaining.count == 1)
        #expect(remaining.first === busy)
        #expect(busy.logEntries?.count == 3)
    }

    @Test("Merges three same-day duplicates into one survivor")
    func mergesMoreThanTwoDuplicates() throws {
        let context = try makeContext()
        let a = DailyEntry(date: Date(timeIntervalSince1970: 0), summary: "a")
        let b = DailyEntry(date: Date(timeIntervalSince1970: 0), summary: "b")
        let c = DailyEntry(date: Date(timeIntervalSince1970: 0), summary: "c")
        context.insert(a)
        context.insert(b)
        context.insert(c)

        mergeAndPruneDuplicateEntries([a, b, c], context: context)

        #expect(try context.fetch(FetchDescriptor<DailyEntry>()).count == 1)
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

// MARK: - DailyLogEntry.tags

@Suite("DailyLogEntry.tags")
struct LogEntryTagsTests {

    @Test("Sorts tags alphabetically and case-insensitively, regardless of stored order")
    func sortedAlphabetically() {
        let log = DailyLogEntry(timestamp: .now, log: "test", score: 0, tagsRaw: "sleep, Focus,deep work,Family")
        #expect(log.tags == ["deep work", "Family", "Focus", "sleep"])
    }

    @Test("Ignores empty segments")
    func ignoresEmptySegments() {
        let log = DailyLogEntry(timestamp: .now, log: "test", score: 0, tagsRaw: ",b, ,a,")
        #expect(log.tags == ["a", "b"])
    }
}
