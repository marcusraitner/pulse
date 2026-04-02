//
//  KPITemplatesSettingsView.swift
//  Pulse
//
//  Created by Marcus Raitner on 31.03.26.
//

import SwiftUI
import SwiftData
import OSLog

struct KPITemplatesSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \KPITemplate.sortOrder) private var templates: [KPITemplate]
    @State private var isPresentingAddTemplate: Bool = false
    @State private var templateToDelete: KPITemplate? = nil
    @State private var templateToEdit: KPITemplate? = nil
    @State private var isPresentingConfirmDelete: Bool = false
   
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "KPITemplatesSettingsView")
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .titleLabelIcon(.orange)
                    Text("Metrics")
                        .font(.title2.bold())
                        .padding(.top, 4)
                    Text("Define your core metrics and add them to your daily reflection.")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                    VStack(alignment: .leading) {
                        HStack {
                            if index < 3 {
                                Image(systemName: "circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            Text(template.title)
                                .font(.headline)
                        }
                        
                        if let note = template.note, !note.isEmpty {
                            Text(note)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let unit = template.unit, !unit.isEmpty {
                            Text("measured in \(unit)")
                                .font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            templateToDelete = template
                            isPresentingConfirmDelete = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            templateToEdit = template
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                }
                .onMove { indices, newOffsets in
                    var reordered = templates
                    reordered.move(fromOffsets: indices, toOffset: newOffsets)
                    for (index, template) in reordered.enumerated() {
                        template.sortOrder = index
                    }
                }
            } footer: {
                Text(" The first 3 metrics appear on your daily reflection card.")
            }
            
            Section {
                Button("Add Metric") {
                    isPresentingAddTemplate = true
                }
            }
        }
        .sheet(isPresented: $isPresentingAddTemplate) {
            KPIEntrySheet()
        }
        .sheet(item: $templateToEdit) { template in
            KPIEntrySheet(template)
        }
        .toolbar {
            EditButton()
        }
        .onDisappear {
            context.saveOrLog("Failed to reorder KPI templates", logger: logger)
        }
        .confirmationDialog("Delete \(templateToDelete?.title ?? "")", isPresented: $isPresentingConfirmDelete) {
            Button("Delete", role: .destructive) {
                if let template = templateToDelete {
                    context.delete(template)
                    context.saveOrLog("Failed to delete KPI template: \(template)", logger: logger)
                }
                templateToDelete = nil
                isPresentingConfirmDelete = false
            }
            Button("Cancel") {
                isPresentingConfirmDelete = false
                templateToDelete = nil
            }
        } message: {
            if let template = templateToDelete {
                let count = template.values?.count ?? 0
                if count == 0 {
                    Text("Are you sure you want to delete the metric \"\(template.title)\"?")
                } else {
                    Text("You currently have \(count) values recorded for the metric \"\(template.title)\". Deleting it will also delete all the values. Are you sure?")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        KPITemplatesSettingsView()
    }
    .modelContainer(SampleData.shared.modelContainer)
}
