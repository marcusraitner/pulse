//
//  HealthMoodLoggerTests.swift
//  PulseTests
//
//  Created by Marcus Raitner on 24.10.26.
//

internal import Foundation
import HealthKit
import Testing
@testable import Pulse

@Suite("HealthMoodLogger")
struct HealthMoodLoggerTests {

    @Test("Maps every score onto HealthKit's valence range",
          arguments: zip([-2, -1, 0, 1, 2], [-1.0, -0.5, 0.0, 0.5, 1.0]))
    func valence(score: Int, expected: Double) {
        #expect(HealthMoodLogger.valence(for: score) == expected)
    }

    @Test("Clamps scores outside −2…+2")
    func valenceClamped() {
        #expect(HealthMoodLogger.valence(for: -5) == -1)
        #expect(HealthMoodLogger.valence(for: 5) == 1)
    }

    @Test("Builds a momentary emotion at the moment's timestamp")
    func sample() {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let sample = HealthMoodLogger.sample(id: UUID(), timestamp: timestamp, score: -1, version: 1)

        #expect(sample.kind == .momentaryEmotion)
        #expect(sample.startDate == timestamp)
        #expect(sample.valence == -0.5)
        #expect(sample.labels.isEmpty)
        #expect(sample.associations.isEmpty)
    }

    @Test("Uses the entry id as sync identifier and carries the version")
    func syncMetadata() {
        let id = UUID()
        let sample = HealthMoodLogger.sample(id: id, timestamp: .now, score: 0, version: 42)

        #expect(sample.metadata?[HKMetadataKeySyncIdentifier] as? String == id.uuidString)
        #expect(sample.metadata?[HKMetadataKeySyncVersion] as? Int == 42)
    }

    // HealthKit only replaces a sample when the version is higher, so edits in quick succession
    // must still produce increasing versions.
    @Test("Sync version increases within the same second")
    func syncVersionIncreases() {
        let first = Date(timeIntervalSince1970: 1_700_000_000)
        let second = first.addingTimeInterval(0.01)
        #expect(HealthMoodLogger.syncVersion(at: second) > HealthMoodLogger.syncVersion(at: first))
    }
}
