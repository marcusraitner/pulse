//
//  KPIEntrySheet.swift
//  Pulse
//
//  Created by Marcus Raitner on 31.03.26.
//

import SwiftUI
import SwiftData
import OSLog

struct KPIEntrySheet: View {
    @Query private var templates: [KPITemplate]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var note: String = ""
    @State private var unit: String = ""
    
    private let template: KPITemplate?
    private var isEditing: Bool { template != nil }
    
    init(_ template: KPITemplate? = nil) {
        self.template = template
        _note = State(initialValue: template?.note ?? "")
        _title = State(initialValue: template?.title ?? "")
        _unit = State(initialValue: template?.unit ?? "")
    }
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "KPIEntrySheet")
    
    private func save() {
        if isEditing, let template = template {
            template.title = title
            template.note = note.isEmpty ? nil : note
            template.unit = unit.isEmpty ? nil : unit
            context.saveOrLog("Failure while saving edited template", logger: logger)
        } else {
            let template = KPITemplate(
                title: title,
                note: note.isEmpty ? nil : note,
                unit: unit.isEmpty ? nil : unit,
                sortOrder: templates.count)
            context.insert(template)
            context.saveOrLog("Failure while saving new template", logger: logger)
        }
    }
    
    
    var body: some View {
        NavigationStack {
            Form {
                if isEditing && (template?.values?.count ?? 0) > 0 {
                    Section {
                        Label {
                            Text("You are editing a metric that already has values. Editing title, note, or unit might change how the values are interpreted.")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                Section {
                    TextField("Title", text: $title)
                    TextField("Description", text: $note)
                    TextField("Unit", text: $unit)
                } footer: {
                    Text("Example: title \"Deep Work\", description \"Time spent on deep work tasks\", unit \"min\"")
                }
            }
            .navigationTitle(isEditing ? "Edit Metric" : "New Metric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

#Preview {
    KPIEntrySheet()
        .modelContainer(SampleData.shared.modelContainer)
}
