//
//  NewLogEntrySheet.swift
//  Pulse
//
//  Created by Marcus Raitner on 21.02.26.
//

import SwiftUI
import OSLog
import SwiftData
import CoreLocation
import CoreLocationUI

struct LogEntrySheet: View {
    // This holds the temporary values of the sheet; initialized in a task to entry
    @State private var newEntry: DailyLogEntry = DailyLogEntry(timestamp: .now, log: "", score: 0)
    // The entry to edit (if passed at all; otherwise defaults to the above values (see init)
    @Binding var entry: DailyLogEntry
    //
    @Binding var isEntryNew: Bool
    // used to manage validation; showing the validation message only if stepper was touched
    @State private var isNew = true
    // closure gets called on save with the values in newEntry
    @State private var isPresentingConfirm = false
    var saveEntry: (DailyLogEntry) -> Void
    
    @StateObject var locationManager = LocationManager()
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private let logger = Logger(subsystem: "de.raitner.pulse", category: "NewLogEntrySheet")

    init(entry: Binding<DailyLogEntry> = .constant(DailyLogEntry(timestamp: .now, log: "", score: 0)),
         isEntryNew: Binding<Bool> = .constant(true), saveEntry: @escaping (DailyLogEntry) -> Void) {
        self._entry = entry
        self._isEntryNew = isEntryNew
        self.saveEntry = saveEntry
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    TextField("What's going on?", text: $newEntry.log, axis: .vertical)
                        .multilineTextAlignment(.leading)
                        .lineLimit(5...Int.max)
                    
                    Text("Please capture your moment here.")
                        .font(.caption)
                        .foregroundStyle(!isNew && newEntry.log.isEmpty ? .red : .clear)
                }
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("How are you feeling?")
                        Text("Capture your mood on a scale from -2 (bad) to 2 (good)")
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    Spacer()
                    VStack {
                        ScoreLabelView(score: newEntry.score, size: 72, radius: 12)
                            .font(.title).bold()
                        Stepper("", value: $newEntry.score, in: -2...2, step: 1)
                            .labelsHidden()
                            .padding(.top, 4)
                    }
                    .padding(.leading)
                }
                
                Text("Recorded at: *\(entry.timestamp.formatted(date: .numeric, time: .shortened))*")
            }
            
            Section {
                VStack {
                    if let location = locationManager.location {
                        Text("Your location: \(location.latitude), \(location.longitude)")
                    }
                    
                    LocationButton {
                        locationManager.requestLocation()
                    }
                    .frame(width: 44, height: 44)
                    .symbolVariant(.fill)
                    .padding()
                }
            }
            
            Section {
                HStack {
                    Spacer()
                    if !isEntryNew {
                        Button("Delete Moment", role: .destructive) {
                            isPresentingConfirm = true
                        }
                        .buttonStyle(.automatic)
                        .confirmationDialog("Are you sure?",
                                            isPresented: $isPresentingConfirm,
                                            titleVisibility: .visible) {
                            Button("Delete", role: .destructive) {
                                context.delete(entry)
                                do {
                                    try context.save()
                                } catch {
                                    logger.error("Failed saving deleted entry: \(String(describing: error))")
                                }
                                dismiss()
                            }
                        } message: {
                            Text("This will delete the moment permanently and cannot be undone.")
                          }
                    }
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
        }
        .task {
            newEntry = DailyLogEntry(timestamp: .now, log: entry.log, score: entry.score)
        }
        .onChange(of: newEntry.score) {
            isNew = false
        }
        .navigationTitle(isEntryNew ? "New Moment" : "Edit Moment")
        .toolbar {
            ToolbarItem (placement: .confirmationAction) {
                if #available(iOS 26, *) {
                    Button(role: .confirm) {
                        saveEntry(newEntry)
                        dismiss()
                    }
                    .disabled(newEntry.log.isEmpty)
                } else {
                    Button("Save") {
                        saveEntry(newEntry)
                        dismiss()
                    }
                    .disabled(newEntry.log.isEmpty)
                }
            }
            ToolbarItem (placement: .cancellationAction) {
                if #available(iOS 26, *) {
                    Button(role: .close) {
                        dismiss()
                    }
                } else {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }

        }
    }
}

#Preview {
    NavigationStack {
        LogEntrySheet() { entry in }
    }
}
