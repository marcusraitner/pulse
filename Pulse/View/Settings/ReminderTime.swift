//
//  ReminderTime.swift
//  Pulse
//
//  Created by Marcus Raitner on 06.10.26.
//

import Foundation

/// A reminder time with a stable identity, so rows survive edits and deletions.
/// Only used while editing: the times are still stored as `[Date]` in `UserDefaults`.
struct ReminderTime: Identifiable, Equatable {
    let id = UUID()
    var time: Date
}
