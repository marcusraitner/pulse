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
