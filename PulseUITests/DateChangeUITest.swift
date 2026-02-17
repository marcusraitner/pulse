//
//  DateChangeUITest.swift
//  PulseUITests
//
//  Created by Marcus Raitner on 17.02.26.
//

import XCTest

final class DateChangeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testNewDailyEntryCreatedOnSceneActivationAfterDayChange() throws {
        let app = XCUIApplication()
        app.launchArguments += ["--remove-today-on-inactive", "--disable-animations"]
        app.launch()
        
        // this represents the main view and is used to access the values for entries and the selectedEntry
        let dateView = app.otherElements["dateView"]
        XCTAssertTrue(dateView.waitForExistence(timeout: 5), "dateView should exist")
        
        // this represents the first element in the timeline for a scroll test
        let firstEntry = app.otherElements["entry0"].firstMatch
        XCTAssertTrue(firstEntry.waitForExistence(timeout: 5), "dateView should exist")
        
        app.activate() // ensure active
        
        // tap on the first entry
        firstEntry.tap()

        // wait a bit with the screenshot
        sleep(2)
       
        // for the moment, only a screenshot; checking scrollposition would be better
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "After tapping first entry"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // set app inactive; this will (with "--remove-today-on-inactive") remove today's entry
        XCUIDevice.shared.press(.home)
        sleep(1)

        // bring it back
        app.activate()
        
        // tap somewhere
        dateView.firstMatch.tap()
        sleep(2)
        
        // take a screenshot
        let attachment2 = XCTAttachment(screenshot: app.screenshot())
        attachment2.name = "After activation from sleep"
        attachment2.lifetime = .keepAlways
        add(attachment2)

        // check that today has been recreated and is selected
        let expectation1 = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            if let selectedDate = self.extractDate(from: dateView.label + " " + dateView.value.debugDescription) {
                return Calendar.current.isDateInToday(selectedDate)
            } else {
                return false
            }
        }, object: nil)
        let result1 = XCTWaiter().wait(for: [expectation1], timeout: 5)
        XCTAssertEqual(result1, .completed, "Expected selected entry being today")
    }
    
    private func extractDate(from text: String?) -> Date? {
        guard let text = text else { return nil }
        
        let RFC3339DateFormatter = DateFormatter()
        RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let range = text.range(of: "selectedEntry:") {
            let suffix = text[range.upperBound...].dropLast()
            // Take the first 26 characters which matches the RFC3339 format length used above
            let date = RFC3339DateFormatter.date(from: String(suffix))
            return date
        }
        
        return nil
    }
}

