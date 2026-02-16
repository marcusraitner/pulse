//
//  DailyEntry.swift
//  collins score
//
//  Created by Marcus Raitner on 12.05.25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class DailyEntry {
    
    // The date of this entry; each day can have at most one entry
    @Attribute(.unique) var date: Date
    
    /// Calcuates the average score of the log entries
    var averageScore: CGFloat {
        let sum = logEntries.reduce(into: 0.0, { sum, x in
            sum += CGFloat(x.score)
        })
        
        return CGFloat(logEntries.isEmpty ? 0.0 : sum / CGFloat(logEntries.count))
    }
    
    // The summary of the day
    var logEntries: [DailyLogEntry]
    
    init(
        date: Date,
        logEntries: [DailyLogEntry] = [],
    ) {
        self.date = date
        self.logEntries = logEntries
    }
}
