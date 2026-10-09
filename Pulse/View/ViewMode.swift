//
//  ViewMode.swift
//  Pulse
//
//  Created by Marcus Raitner on 09.10.26.
//

import Foundation

/// The three ways to look at the journal: one day, one week or one month.
enum ViewMode: String, CaseIterable {
    case day, week, month

    var systemImage: String {
        switch self {
        case .day: "calendar.day.timeline.left"
        case .week: "rectangle.split.3x1"
        case .month: "calendar"
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .day: "Day"
        case .week: "Week"
        case .month: "Month"
        }
    }
}
