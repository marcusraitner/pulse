//
//  SampleDataSeedTests.swift
//  PulseTests
//
//  Created by Marcus Raitner on 11.10.26.
//

internal import Foundation
import SwiftData
import Testing
@testable import Pulse

@MainActor
@Suite("SampleData seed")
struct SampleDataSeedTests {

    /// Held for the whole test: once a container is released, its models can no longer be read.
    private let samples: [SampleData.SeedLanguage: SampleData] = Dictionary(
        uniqueKeysWithValues: SampleData.SeedLanguage.allCases.map { ($0, SampleData(language: $0)) }
    )

    /// Seeded days, newest first, so that `days[i]` is `i` days before today.
    private func seededDays(_ language: SampleData.SeedLanguage) throws -> [DailyEntry] {
        let container = try #require(samples[language]).modelContainer
        let descriptor = FetchDescriptor<DailyEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try container.mainContext.fetch(descriptor)
    }

    private func sortedLogs(of day: DailyEntry) -> [DailyLogEntry] {
        (day.logEntries ?? []).sorted { $0.timestamp < $1.timestamp }
    }

    @Test("Days are consecutive back from today, without gaps", arguments: SampleData.SeedLanguage.allCases)
    func consecutiveDays(language: SampleData.SeedLanguage) throws {
        let days = try seededDays(language)
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        #expect(days.count == SampleData.seedDayCount)
        for (index, day) in days.enumerated() {
            let expected = cal.date(byAdding: .day, value: -index, to: today)
            #expect(cal.startOfDay(for: day.date) == expected, "day \(index)")
        }
    }

    @Test("Every day has a moment; older days exactly one and no forecast or reflection", arguments: SampleData.SeedLanguage.allCases)
    func momentsPerDay(language: SampleData.SeedLanguage) throws {
        let days = try seededDays(language)

        for (index, day) in days.enumerated() {
            let count = day.logEntries?.count ?? 0
            if index < SampleData.detailedDayCount {
                #expect(count >= 1, "day \(index)")
                #expect(!day.morning.isEmpty, "day \(index)")
                #expect(!day.summary.isEmpty, "day \(index)")
            } else {
                #expect(count == 1, "day \(index)")
                #expect(day.morning.isEmpty, "day \(index)")
                #expect(day.summary.isEmpty, "day \(index)")
                #expect(day.kpiValues?.isEmpty ?? true, "day \(index)")
            }
        }
    }

    @Test("Today has a forecast and a reflection", arguments: SampleData.SeedLanguage.allCases)
    func todayHasForecastAndReflection(language: SampleData.SeedLanguage) throws {
        let today = try #require(try seededDays(language).first)
        #expect(!today.morning.isEmpty)
        #expect(!today.summary.isEmpty)
    }

    /// Catches missing or mistyped keys in the English → German dictionaries.
    @Test("Every German text is translated")
    func germanTextsAreTranslated() throws {
        let english = try seededDays(.en)
        let german = try seededDays(.de)
        try #require(english.count == german.count)

        for (index, (en, de)) in zip(english, german).enumerated() {
            if !en.summary.isEmpty { #expect(en.summary != de.summary, "summary of day \(index)") }
            if !en.morning.isEmpty { #expect(en.morning != de.morning, "morning of day \(index)") }

            let enLogs = sortedLogs(of: en)
            let deLogs = sortedLogs(of: de)
            try #require(enLogs.count == deLogs.count)
            for (enLog, deLog) in zip(enLogs, deLogs) {
                #expect(enLog.log != deLog.log, "untranslated: \(enLog.log)")
            }
        }
    }
}
