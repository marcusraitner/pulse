//
//  TagSettingsView.swift
//  Pulse
//
//  Created by Marcus Raitner on 29.04.26.
//

import SwiftUI
import SwiftData
import OSLog

struct TagSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Tag.name) private var tags: [Tag]
    @Query private var logs: [DailyLogEntry]
    @State private var tagToDelete: Tag?
    @State private var isPresentingDeleteAlert: Bool = false
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "TagSettingsView")
    
    private func countTags(for tag: Tag) -> Int {
        let count = logs.filter( { $0.tags.contains(tag.name) }).count
        return count
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Image(systemName: "tag.circle.fill")
                        .titleLabelIcon(.teal)
                    Text("Tags")
                        .font(.title2.bold())
                    Text("Edit your tags here")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                if tags.isEmpty {
                    ContentUnavailableView {
                        Label("No tags", systemImage: "tag.slash")
                    } description: {
                        Text("Add some tags to get started")
                    }
                } else {
                    ForEach(tags) { tag in
                        TagRowView(tag: tag, entriesCount: countTags(for: tag))
                        .swipeActions {
                            Button {
                                tagToDelete = tag
                                isPresentingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                                    .tint(Color(.systemRed))
                            }
                        }
                    }
                }
            }
        }
        .confirmationDialog("Delete Tag \(tagToDelete?.name ?? "")", isPresented: $isPresentingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let tag = tagToDelete {
                    for log in logs where log.tags.contains(tag.name) {
                        log.tagsRaw = log.tags.filter { $0 != tag.name }.joined(separator: ",")
                    }
                    context.delete(tag)
                    context.saveOrLog("Failed to delete tag", logger: logger)
                }
                tagToDelete = nil
                isPresentingDeleteAlert = false
            }
            Button("Cancel") {
                tagToDelete = nil
                isPresentingDeleteAlert = false
            }
        } message: {
            if let tag = tagToDelete {
                Text("Are you sure you want to delete the tag '\(tag.name)'? It is used in \(countTags(for: tag)) entries and will be permanently removed from them.")
            }
        }
    }
}

#Preview {
    TagSettingsView()
        .modelContainer(SampleData.shared.modelContainer)
}
