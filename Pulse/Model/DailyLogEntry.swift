//
//  DailyLogEntry.swift
//  collins score
//
//  Created by Marcus Raitner on 16.05.25.
//

import Foundation
import SwiftData

@Model
class DailyLogEntry: Identifiable {
    var id = UUID()
    var timestamp: Date
    var log: String
    var score: Int
    
    var formatedTimestamp: String {
        self.timestamp.formatted(.dateTime.hour().minute())
    }
    
    init(timestamp: Date, log: String, score: Int) {
        self.timestamp = timestamp
        self.log = log
        self.score = score
    }
}
