//
//  MindfulSessionTests.swift
//  PulseTests
//
//  Created by Marcus Raitner on 25.10.26.
//

internal import Foundation
import HealthKit
import Testing
@testable import Pulse

private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

private func at(_ seconds: TimeInterval) -> Date {
    t0.addingTimeInterval(seconds)
}

@Suite("ReflectionSession")
struct ReflectionSessionTests {

    @Test("Counts time while running")
    func running() {
        var session = ReflectionSession()
        session.start(at: at(0))
        #expect(session.foregroundDuration(at: at(90)) == 90)
    }

    @Test("Does not count time in the background")
    func excludesBackground() {
        var session = ReflectionSession()
        session.start(at: at(0))
        session.pause(at: at(40))
        session.resume(at: at(3_600))  // an hour in the background
        #expect(session.foregroundDuration(at: at(3_630)) == 70)
    }

    @Test("Repeated pause and resume add up the foreground stretches")
    func repeatedPauseResume() {
        var session = ReflectionSession()
        session.start(at: at(0))
        session.pause(at: at(10))
        session.pause(at: at(500))  // already paused: ignored
        session.resume(at: at(600))
        session.resume(at: at(700))  // already running: ignored
        session.pause(at: at(620))
        #expect(session.foregroundDuration(at: at(9_999)) == 30)
    }

    @Test("Start resets earlier time")
    func startResets() {
        var session = ReflectionSession()
        session.start(at: at(0))
        session.start(at: at(100))
        #expect(session.foregroundDuration(at: at(130)) == 30)
    }

    @Test("Only morning and summary count as changes")
    func reflectionChanges() {
        #expect(ReflectionSession.hasReflectionChanges(morning: "new", summary: "",
                                                       originalMorning: "", originalSummary: ""))
        #expect(ReflectionSession.hasReflectionChanges(morning: "", summary: "new",
                                                       originalMorning: "", originalSummary: ""))
        // unchanged texts, e.g. only metric values were entered
        #expect(!ReflectionSession.hasReflectionChanges(morning: "a", summary: "b",
                                                        originalMorning: "a", originalSummary: "b"))
    }
}

@Suite("MindfulSessionLogger")
struct MindfulSessionLoggerTests {

    @Test("Sessions under the minimum are not logged")
    func belowMinimum() {
        #expect(MindfulSessionLogger.duration(for: 59) == nil)
        #expect(MindfulSessionLogger.duration(for: 0) == nil)
    }

    @Test("Sessions from the minimum up are logged as measured")
    func withinRange() {
        #expect(MindfulSessionLogger.duration(for: 60) == TimeInterval(60))
        #expect(MindfulSessionLogger.duration(for: 600) == TimeInterval(600))
    }

    @Test("Long sessions are capped at the maximum")
    func capped() {
        #expect(MindfulSessionLogger.duration(for: 2_700) == TimeInterval(1_800))
    }

    @Test("Builds a mindful session ending at the save time")
    func sample() {
        let end = at(1_000)
        let sample = MindfulSessionLogger.sample(duration: 120, endingAt: end)

        #expect(sample.categoryType == HKCategoryType(.mindfulSession))
        #expect(sample.value == HKCategoryValue.notApplicable.rawValue)
        #expect(sample.endDate == end)
        #expect(sample.startDate == at(880))
        #expect(sample.metadata?[HKMetadataKeySyncIdentifier] == nil)
    }
}
