//
//  SampleDataLaunchArgumentTests.swift
//  PulseTests
//
//  Created by Marcus Raitner on 11.10.26.
//

internal import Foundation
import Testing
@testable import Pulse

@MainActor
@Suite("SampleData launch argument")
struct SampleDataLaunchArgumentTests {

    /// Runs `body` against a throwaway `UserDefaults` suite, so the real defaults are never touched.
    private func withDefaults(value: String?, _ body: (UserDefaults) -> Void) {
        let suiteName = "SampleDataLaunchArgumentTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        if let value {
            defaults.set(value, forKey: SampleData.launchArgumentKey)
        }
        body(defaults)
    }

    @Test("Maps de and en to the seed language", arguments: [
        ("de", SampleData.SeedLanguage.de),
        ("en", SampleData.SeedLanguage.en),
    ])
    func knownLanguage(value: String, expected: SampleData.SeedLanguage) {
        withDefaults(value: value) { defaults in
            #expect(SampleData.launchArgumentLanguage(from: defaults) == expected)
        }
    }

    @Test("Starts with the real data without the argument")
    func missingArgument() {
        withDefaults(value: nil) { defaults in
            #expect(SampleData.launchArgumentLanguage(from: defaults) == nil)
        }
    }

    @Test("Starts with the real data for an unknown language")
    func unknownLanguage() {
        withDefaults(value: "fr") { defaults in
            #expect(SampleData.launchArgumentLanguage(from: defaults) == nil)
        }
    }
}
