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
    @FocusState private var isFocused: Bool
    @State private var scoreChanged: Bool = false
    
    private var isValid: Bool {
        return !newLog.isEmpty
    }
    
    @Binding var logEntries: [DailyLogEntry]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    TextField("What's going on?", text: $newLog, axis: .vertical)
                        .lineLimit(2, reservesSpace: true)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.leading)
                        .focused($isFocused)
                        .overlay(alignment: .bottom) {
                            if !isValid && scoreChanged {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundStyle(.red)
                            }
                        }
                    Text("Enter something")
                        .font(.caption)
                        .foregroundStyle(!isValid && scoreChanged ? .red : .clear)
                }
                Button {
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
                        isFocused = false
                        scoreChanged = false
                    }
                } label: {
                    Label("Add", systemImage: isValid ? "checkmark.circle.fill" : "checkmark.circle")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.accent)
                        .font(.title)
                }
                .buttonStyle(.plain)
                .padding(4)
//                .background(.thinMaterial, in: Circle())
                .disabled(!isValid)

            }
            HStack {
                Stepper(value: $newScore, in: -2...2, step: 1) {
                    Text("How are you feeling?")
                }
                ScoreLabelView(score: newScore)
                    .padding(.leading, 2)
            }
//            .padding(.top, 4)
            .onChange(of: newScore) {
                if !scoreChanged {
                    scoreChanged = true
                }
            }
        }
        .padding()
    }
}



#Preview {
    @Previewable @State var logEntries: [DailyLogEntry] = []

    NewLogEntryView(logEntries: $logEntries)
}

