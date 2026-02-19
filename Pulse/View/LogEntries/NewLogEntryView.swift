//
//  NewLogEntryView.swift
//  collins score
//
//  Created by Marcus Raitner on 31.01.26.
//

import SwiftUI

struct NewLogEntryView: View {
    @State var newLog: String = ""
    @State var newScore: Int = 0
    @Binding var logEntries: [DailyLogEntry]
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                TextField("What's going on?", text: $newLog)
                    .submitLabel(.done)
                    .onSubmit {
                        if !newLog.isEmpty {
                            logEntries.append(
                                DailyLogEntry(
                                    timestamp: Date.now,
                                    log: newLog,
                                    score: newScore
                                )
                            )
                            newLog = ""
                            newScore = 0
                        }
                    }
                HStack {
                    Stepper(value: $newScore, in: -2...2, step: 1) {
                        Text("How are you feeling?")
                    }
                    ScoreLabelView(score: newScore)
                        .padding(.leading, 2)
                }
                .padding(.top, 4)
            }
        }
        .padding()
    }
}



#Preview {
    @Previewable @State var logEntries: [DailyLogEntry] = []

    NewLogEntryView(logEntries: $logEntries)
}
