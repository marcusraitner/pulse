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

    /// Explicit arguments and an empty environment, so the scheme of the test run never leaks in.
    private func language(_ arguments: [String], environment: [String: String] = [:]) -> SampleData.SeedLanguage? {
        SampleData.launchArgumentLanguage(arguments: ["Pulse"] + arguments, environment: environment)
    }

    @Test("Maps de and en to the seed language", arguments: [
        ("de", SampleData.SeedLanguage.de),
        ("en", SampleData.SeedLanguage.en),
    ])
    func knownLanguage(value: String, expected: SampleData.SeedLanguage) {
        #expect(language(["-sampleData", value]) == expected)
    }

    @Test("Starts with the real data without the argument")
    func missingArgument() {
        #expect(language([]) == nil)
    }

    @Test("Starts with the real data for an unknown language")
    func unknownLanguage() {
        #expect(language(["-sampleData", "fr"]) == nil)
    }

    @Test("Starts with the real data when the value is missing")
    func missingValue() {
        #expect(language(["-sampleData"]) == nil)
    }

    @Test("Ignores the argument when hosting unit tests")
    func ignoredAsTestHost() {
        #expect(language(["-sampleData", "de"], environment: ["XCTestConfigurationFilePath": "/tmp/x.xctestconfiguration"]) == nil)
    }
}
