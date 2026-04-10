//
//  DateRangeCalculator.swift
//  Pulse
//
//  Created by Marcus Raitner on 08.04.26.
//

import Foundation

struct DateRangeCalculator {
    static func getWeek(for date: Date) -> DateInterval? {
        let cal = Calendar.current
        return cal.dateInterval(of: .weekOfYear, for: date)
    }
}
