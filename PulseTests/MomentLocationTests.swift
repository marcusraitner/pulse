//
//  MomentLocationTests.swift
//  PulseTests
//
//  Created by Marcus Raitner on 06.11.26.
//

internal import Foundation
import Testing
@testable import Pulse

@Suite("MomentLocation")
struct MomentLocationTests {

    private func makeEntry(latitude: Double? = nil, longitude: Double? = nil, address: String? = nil) -> DailyLogEntry {
        DailyLogEntry(timestamp: .now, log: "Test", score: 0, latitude: latitude, longitude: longitude, address: address)
    }

    @Test("Entry without coordinates has no location")
    func noLocation() {
        #expect(makeEntry().location == nil)
        #expect(makeEntry(latitude: 48.1, address: "Munich").location == nil)
    }

    @Test("Reads all three fields")
    func read() {
        let entry = makeEntry(latitude: 48.1, longitude: 11.5, address: "Munich")
        #expect(entry.location == MomentLocation(latitude: 48.1, longitude: 11.5, address: "Munich"))
    }

    @Test("Setting a new location replaces all fields, including a missing address")
    func replace() {
        let entry = makeEntry(latitude: 48.1, longitude: 11.5, address: "Munich")
        entry.location = MomentLocation(latitude: 52.5, longitude: 13.4, address: nil)

        #expect(entry.latitude == 52.5)
        #expect(entry.longitude == 13.4)
        #expect(entry.address == nil)
    }

    @Test("Setting nil clears coordinates and address")
    func clear() {
        let entry = makeEntry(latitude: 48.1, longitude: 11.5, address: "Munich")
        entry.location = nil

        #expect(entry.latitude == nil)
        #expect(entry.longitude == nil)
        #expect(entry.address == nil)
    }
}
