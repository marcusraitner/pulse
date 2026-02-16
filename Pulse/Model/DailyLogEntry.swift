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
    
    init(timestamp: Date, log: String, score: Int) {
        self.timestamp = timestamp
        self.log = log
        self.score = score
    }
}
