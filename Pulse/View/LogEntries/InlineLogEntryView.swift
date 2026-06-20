//
//  InlineLogEntryView.swift
//  Pulse
//
//  Created by Marcus Raitner on 12.06.26.
//

import SwiftUI
import SwiftData
import OSLog
import MapKit

// TODO: Always work on a DailyLogEntry (either newly created or already existing)
struct InlineLogEntryView: View {
    let day: DailyEntry
    
    init(for day: DailyEntry, isEditing: Binding<Bool>) {
        self.day = day
        self._isEditing = isEditing
    }
   
    @Query private var tags: [Tag]
    
    @State private var timestamp: Date = .init()
    @State private var log = ""
    @State private var score: Float = 0.0
    @State private var entryTags: Set = Set<String>()
    @Binding var isEditing: Bool
    @State private var address: String?
    @State private var latitude: Double?
    @State private var longitude: Double?
    
    @State private var locationManager = LocationManager()
    
    @FocusState private var isFocused: Bool
    
    @Environment(\.modelContext) private var context
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "InlineLogEntryView")
    
    private func save() {
        let entry = DailyLogEntry(
            timestamp: timestamp,
            log: log,
            score: Int(score),
            entry: day,
            latitude: latitude,
            longitude: longitude,
            address: address,
            tagsRaw: entryTags.joined(separator: ","))
        
        context.insert(entry)
        context.saveOrLog("Failed to create new log entry", logger: logger)
    }
    
    private func setItem(item: MKMapItem) -> Void {
        let coordinate = Compat.coordinate(from: item)
        latitude = coordinate.latitude
        longitude = coordinate.longitude
        address = Compat.address(from: item)
    }
    
    private func reset() {
        timestamp = .now
        log = ""
        entryTags = .init()
        score = 0.0
        address = nil
        latitude = nil
        longitude = nil
        isFocused = false
    }
    
    var body: some View {
        if isEditing {
            ZStack (alignment: .topTrailing) {
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        Text(timestamp.formatted(.dateTime.hour().minute()))
                        TextField("New Log", text: $log, axis: .vertical)
                            .padding(.trailing, 50)
                            .focused($isFocused)
                    }
                    
                    HStack {
                        Slider(value: $score, in: -2...2, step: 1)
                        ScoreLabelView(score: Int(score), style: .badge)
                            .padding(.leading, 10)
                    }
                    
                    FlowLayout {
                        ForEach(tags) { tag in
                            TagChipView(
                                label: tag.name,
                                style: .selectable(
                                    isSelected: entryTags.contains(tag.name),
                                    onTap: {
                                        entryTags.formSymmetricDifference([tag.name])
                                    }
                                )
                            )
                        }
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 8)
                    
                    if let address {
                        HStack(alignment: .top) {
                            Button {
                                self.address = nil
                            } label: {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                            }
                            
                            Text(address)
                                .font(.caption)
                        }
                    } else {
                        Button {
                            locationManager.setItem = self.setItem
                            locationManager.requestLocation()
                        } label: {
                            Image(systemName: "location.slash.fill")
                                .font(.caption)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .glassBackground()
                
                HStack {
                    Button("Save", systemImage: "checkmark") {
                        save()
                        reset()
                        withAnimation(.bouncy) {
                            isEditing = false
                        }
                    }
                    .labelStyle(.iconOnly)
                    Button("Cancel", systemImage: "xmark") {
                        reset()
                        withAnimation(.bouncy) {
                            isEditing = false
                        }
                    }
                    .labelStyle(.iconOnly)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding()
            }
        } else {
            HStack {
                Button("Add Log", systemImage: "plus.circle") {
                    reset()
                    
                    withAnimation(.bouncy) {
                        isEditing = true
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .padding(.vertical, 1)
            .glassBackground()
        }
    }
}

#Preview {
    @Previewable @State var isEditing: Bool = false
    InlineLogEntryView(for: .init(date: .now), isEditing: $isEditing)
}
