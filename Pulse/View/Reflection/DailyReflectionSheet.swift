//
//  DailyReflectionSheet.swift
//  Pulse
//
//  Created by Marcus Raitner on 05.03.26.
//

import SwiftUI
import SwiftData
import OSLog

/// Modal sheet for composing or editing the day's free-text reflection.
/// Shows the existing log entries for context and offers a rotating coaching question
/// when no reflection has been written yet.
struct DailyReflectionSheet: View {
    enum FocusField: Hashable {
        case summary
        case morning
        case kpi(UUID)
    }
    
    let day: DailyEntry
    
    @Query private var kpiTemplates: [KPITemplate]
    
    @State private var kpiValues: [UUID : String] = [:]
    @State private var reflection: String = ""
    @State private var morning: String = ""
    @State private var coachingQuestionIndex: Int = 0
    @FocusState private var focusedField: FocusField?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.featureFlags) private var featureFlags
    @Environment(\.modelContext) private var context
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "DailyReflectionSheet")

    /// Localization keys for the pool of coaching questions shown below the reflection field.
    private static let questionKeys = [
        "stoic.reflection.1",
        "stoic.reflection.2",
        "stoic.reflection.3",
    ]

    /// Replaces the current coaching question with a different randomly selected one.
    private func pickAnotherQuestion() {
        coachingQuestionIndex = (coachingQuestionIndex + 1) % Self.questionKeys.count
    }

    private func kpiBinding(for template: KPITemplate) -> Binding<String> {
        Binding (
            get: { kpiValues[template.id] ?? "" },
            set: { kpiValues[template.id] = $0 })
    }
    
    private func save() {
        day.summary = reflection
        day.morning = morning

        for template in kpiTemplates {
            let existing = day.kpiValues?.first(where: { $0.template?.id == template.id })
            let inputText = kpiValues[template.id] ?? ""
            
            if let value = Int(inputText) {
                // a value is provided for this metric
                if let existing {
                    // this is an update of an existing metric value
                    existing.value = value
                } else {
                    // a new metric value needs to be created
                    let newValue = DailyKPIValue(value: value, template: template, entry: day)
                    context.insert(newValue)
                }
                context.saveOrLog("Failed to save DailyKPIValue", logger: logger)
            } else if let existing {
                // field was cleared
                context.delete(existing)
                context.saveOrLog("Failed to delete DailyKPIValue", logger: logger)
            }
        }
        
        
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            List {
                Section {
                    TextField("What do you expect today?", text: $morning, axis: .vertical)
                        .multilineTextAlignment(.leading)
                        .lineLimit(5...Int.max)
                        .focused($focusedField, equals: .morning)
                } header: {
                    Text("Forecast")
                } footer: {
                    Text("What might be hard today — once anticipated, it won't catch you off guard. One sentence is enough.")
                }
                .onAppear() {
                    focusedField = .morning
                }

                Section {
                    TextField("Summarize your day", text: $reflection, axis: .vertical)
                        .multilineTextAlignment(.leading)
                        .lineLimit(5...Int.max)
                        .focused($focusedField, equals: .summary)
                } header: {
                    Text("Reflect Your Day")
                } footer: {
                    let question = Self.questionKeys[coachingQuestionIndex]
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey(question))
                        HStack {
                            Spacer()
                            Button(action: pickAnotherQuestion) {
                                Label("New question", systemImage: "arrow.clockwise")
                                    .font(.footnote)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.tint)
                            .padding(.top, 2)
                            
                        }
                    }
                        
                }
                .onAppear() {
                    focusedField = .summary
                }
                
                if !kpiTemplates.isEmpty {
                    Section {
                        ForEach(kpiTemplates) { template in
                            HStack(alignment: .top) {
                                VStack (alignment: .leading) {
                                    Text(template.title)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .padding(.vertical, 4)
                                    Text(template.note ?? "")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.trailing, 4)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    TextField("—", text: kpiBinding(for: template))
                                        .multilineTextAlignment(.trailing)
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: .kpi(template.id))
                                        .frame(width: 70)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                                    
                                    Text(template.unit ?? "")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                        .padding(.trailing, 4)
                                }
                            }
                        }
                    } header: {
                        Text("Metrics")
                    }
                }
                Section {
                    if let logEntries = day.logEntries, !logEntries.isEmpty {
                        ForEach(day.logEntries?.sorted(by: { $0.timestamp < $1.timestamp } ) ?? []) { logEntry in
                            NavigationLink {
                                LogEntrySheet(day: day, entry: logEntry, isModal: false)
                            } label: {
                                LogEntryText(logEntry: logEntry)
                            }
                        }
                    }
                } header: {
                    Text("Moments")
                } footer: {
                    if day.logEntries?.isEmpty ?? true {
                        Text("No moments logged for this day.")
                    }
                }
            }
        }
        .navigationTitle("\(day.date.formatted(.dateTime.weekday(.wide).day().month(.defaultDigits).year(.twoDigits)))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) {
                    save()
                    dismiss()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .close) { dismiss() }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    focusedField = nil
                } label: {
                    Label("Done", systemImage: "keyboard.chevron.compact.down")
                }
            }
        }
        .task {
            reflection = day.summary
            morning = day.morning
            
            for value in day.kpiValues ?? [] {
                if let template = value.template {
                    kpiValues[template.id] = String(value.value)
                }
            }
        }
    }
}


struct DailyReflectionSheetPreviewContainer: View {
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries:
        [DailyEntry]

    var body: some View {
        if let entry = entries.first {
            DailyReflectionSheet(day: entry)
        } else {
            Text("No sample data available")
                .padding()
        }
    }
}

#Preview("filled") {
    NavigationStack {
        DailyReflectionSheetPreviewContainer()
    }
    .modelContainer(SampleData.shared.modelContainer)
    .preferredColorScheme(.dark)
}

#Preview("empty") {
    NavigationStack {
        DailyReflectionSheet(day: .init(date: .now))
    }
    .modelContainer(SampleData.shared.modelContainer)
    .preferredColorScheme(.dark)
}

