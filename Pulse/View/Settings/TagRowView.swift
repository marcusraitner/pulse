//
//  TagRowView.swift
//  Pulse
//
//  Created by Marcus Raitner on 30.04.26.
//

import SwiftUI
import SwiftData
import OSLog

struct TagRowView: View {
    @State private var isEditing: Bool = false
    @State private var draftName: String = ""
    @FocusState private var isFocused: Bool
    @Query private var entries: [DailyLogEntry]
    @Query private var allTags: [Tag]
    @Environment(\.modelContext) private var context
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "TagRowView")
    
    let tag: Tag
    let entriesCount: Int
    
    private func commit() {
        guard isEditing else { return }
        
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != tag.name, !allTags.contains(where: { $0.name == trimmed }) else {
            draftName = tag.name
            isEditing = false
            return
        }
        
        for entry in entries where entry.tags.contains(tag.name) {
            entry.tagsRaw = entry.tags.map { $0 == tag.name ? trimmed : $0 }.joined(separator: ",")
        }
        
        tag.name = trimmed
        context.saveOrLog("Failed to update tag", logger: logger)
        isEditing = false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ZStack(alignment: .leading) {
                Text(draftName.isEmpty ? tag.name : draftName)
                    .padding(.vertical, 2)
                    .opacity(isEditing ? 0 : 1)

                TextField("Tag name", text: $draftName)
                    .opacity(isEditing ? 1 : 0)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        commit()
                    }
            }
            .animation(.smooth, value: isEditing)

            Text("\(entriesCount) entries")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isEditing else { return }
            isEditing = true
        }
        .onChange(of: isEditing) { _, editing in
            if editing {
                draftName = tag.name
                isFocused = true
            }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                commit()
            }
        }
    }
}

#Preview {
    TagRowView(tag: .init(name: "Familie"), entriesCount: 42)
    TagRowView(tag: .init(name: "Deep Work"), entriesCount: 0)
}
