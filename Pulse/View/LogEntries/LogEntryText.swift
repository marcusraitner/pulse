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
            VStack (alignment: .leading) {
                Text("\(Text(logEntry.formattedTimestamp).bold()): \(Text("\(logEntry.log)"))")
                if let address = logEntry.address {
                    Label("\(address)", systemImage: "location.circle.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 5)
                }
            }
            Spacer()
            ScoreLabelView(score: logEntry.score, opacity: 0.5)
        }
    }
}
#Preview {
    LogEntryText(logEntry: DailyLogEntry(timestamp: Date.now, log: "Something", score: 2))
}
