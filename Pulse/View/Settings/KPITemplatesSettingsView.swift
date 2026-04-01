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
    @Query private var templates: [KPITemplate]
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
                ForEach(templates, id: \.id) { template in
                    VStack(alignment: .leading) {
                        Text(template.title).font(.headline)
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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        templateToEdit = template
                    }
                }
                
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
        .confirmationDialog("Delete \(templateToDelete?.title ?? "")", isPresented: $isPresentingConfirmDelete) {
            Button("Delete", role: .destructive) {
                if let template = templateToDelete {
                    context.delete(template)
                    context.saveOrLog("Failed to delete KPI template: \(template)", logger: logger)
                }
                templateToDelete = nil
                isPresentingConfirmDelete = false
            }
            Button("Cancel", role: .cancel) {
                templateToDelete = nil
                isPresentingConfirmDelete = false
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
