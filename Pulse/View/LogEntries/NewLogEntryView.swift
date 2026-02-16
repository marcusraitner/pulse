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
            HStack {
                TextField("What's going on?", text: $newLog)
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
                    .submitLabel(.done)

                Stepper(value: $newScore, in: -2...2, step: 1) {
                    ScoreLabelView(score: newScore)
                }
                .fixedSize()
            }

            Text(
                "Note what is on your mind or what is happening and rate how you are feeling about this from -2 (bad) to 2 (good)."
            )
            .font(.footnote)
            .padding(.top)
        }
        .padding()
    }
}



#Preview {
    @Previewable @State var logEntries: [DailyLogEntry] = [
        //        DailyLogEntry(timestamp: Date.now, log: "AWESOME!", score: 2),
        //      DailyLogEntry(timestamp: Date.now.addingTimeInterval(-20000), log: "NOT SO GREAT...", score: -1)
    ]

    NewLogEntryView(logEntries: $logEntries)
}
