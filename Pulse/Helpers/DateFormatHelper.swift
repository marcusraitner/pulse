//
//  DateFormatter.swift
//  Pulse
//
//  Created by Marcus Raitner on 23.02.26.
//

import Foundation

struct DateFormatHelper {
    static func formatDate(_ date: Date?) -> String {
        if let date {
            let RFC3339DateFormatter = DateFormatter()
            RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
            RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            return RFC3339DateFormatter.string(from: date)
        } else {
            return ""
        }
    }
}
