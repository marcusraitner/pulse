//
//  LogEntryText.swift
//  collins score
//
//  Created by Marcus Raitner on 29.01.26.
//

import SwiftUI

struct LogEntryText: View {
    var logEntry: DailyLogEntry
    
    var body: some View {
        HStack(alignment: .top) {
            Text(
                    """
                    \(Text(logEntry.timestamp.formatted(.dateTime
                            .hour()
                            .minute()))
                        .bold()): \
                    \(Text("\(logEntry.log)"))
                    """)
            Spacer()

            ScoreLabelView(score: logEntry.score)
        }
    }
}
#Preview {
    LogEntryText(logEntry: DailyLogEntry(timestamp: Date.now, log: "Something", score: 2))
}
