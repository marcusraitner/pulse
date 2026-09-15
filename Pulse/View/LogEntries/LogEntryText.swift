//
//  LogEntryText.swift
//  collins score
//
//  Created by Marcus Raitner on 29.01.26.
//

import SwiftUI

/// A row view that renders a single log entry: bold timestamp, log text, optional location label, and a score badge.
struct LogEntryText: View {
    var logEntry: DailyLogEntry
    
    var body: some View {
        VStack (alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(logEntry.formattedTimestamp).bold()
                ScoreLabelView(score: logEntry.score, style: .inline)
            }
            
            Text(logEntry.log)
            
            if !logEntry.tags.isEmpty {
                FlowLayout {
                    ForEach(logEntry.tags, id: \.self) { tag in
                        TagChipView(label: tag, style: .display)
                    }
                }
            }
            if let address = logEntry.address {
                Label("\(address)", systemImage: "location.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#Preview {
    LogEntryText(logEntry: DailyLogEntry(timestamp: Date.now, log: "Something", score: 2, latitude: nil, longitude: nil, address: nil, tagsRaw: "Deep Work, Focus"))
        .preferredColorScheme(.dark)
}
