//
//  InlineLogEntryView.swift
//  Pulse
//
//  Created by Marcus Raitner on 12.06.26.
//

import MapKit
import OSLog
import SwiftData
import SwiftUI

struct InlineLogEntryView: View {
    /// The log entry shown and or edited in this view
    /// Persistence is handled in the List containing these views
    @Bindable var logEntry: DailyLogEntry
    
    /// Managing the focus of a list of 'InlineLogEntryView' elements
    /// Uses the 'timestamp' of a 'DailyLogEntry' as id
    var focused: FocusState<InlineFocusField?>.Binding
    
    var scoreProxy: Binding<Double> {
        Binding<Double>(
            get: {
                //returns the score as a Double
                return Double(logEntry.score)
            }, set: {
                //rounds the double to an Int
                logEntry.score = Int($0)
            })
    }
    
    var isEditing: Bool {
        guard let focused = focused.wrappedValue else {
            return false
        }

        switch focused {
        case .tagField(let timestamp):
            return timestamp == logEntry.timestamp
        case .log(let timestamp):
            return timestamp == logEntry.timestamp
        }
    }

    var tagSet: Set<String> {
        Set(logEntry.tags)
    }

    @Query private var tags: [Tag]
    @State private var locationManager = LocationManager()
    @State private var newTag: String = ""
    @State private var showNewTagField: Bool = false
    @AppStorage(AppStorageKeys.theme) var themeName: String = "traffic"
    @Environment(\.modelContext) private var context

    private let logger = Logger(
        subsystem: "de.raitner.pulse",
        category: "InlineLogEntryView"
    )

    private func setItem(item: MKMapItem) {
        let coordinate = Compat.coordinate(from: item)
        logEntry.latitude = coordinate.latitude
        logEntry.longitude = coordinate.longitude
        logEntry.address = Compat.address(from: item)
    }

    private var sanitizedNewTag: String {
        newTag.replacingOccurrences(of: ",", with: "").trimmingCharacters(
            in: .whitespaces
        )
    }

    private var isNewTagValid: Bool {
        let name = sanitizedNewTag
        guard !name.isEmpty else { return false }
        return !tags.contains(where: {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        })
    }

    private func addCustomTag() {
        // Button calling this is checking isNewTagValid before, but let's make it explicit
        guard isNewTagValid else { return }
        let name = sanitizedNewTag
        context.insert(Tag(name: name))
        logEntry.tagsRaw = tagSet.union([name]).joined(separator: ",")
        newTag = ""
    }

    var body: some View {
        VStack(alignment: .leading) {
            // MARK: Log entry and score
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        logEntry.timestamp.formatted(
                            .dateTime.hour().minute()
                        )
                    )
                    .bold()
                    TextField(
                        "New Log",
                        text: $logEntry.log,
                        axis: .vertical
                    )
                    .focused(
                        focused,
                        equals: .log(timestamp: logEntry.timestamp)
                    )
                    .padding(.bottom, 4)
                }
                Spacer()
                HStack {
                    if isEditing {
                        VerticalStepper(value: $logEntry.score, range: -2...2, step: 1, size: 28)
                        //                    Stepper("", value: $logEntry.score, step: 1)
                    } else {
                        Color.clear
                            .frame(width: 28, height: 28)
                    }
                    ScoreLabelView(score: logEntry.score, style: .badge)
                }
            }
            
//            // MARK: Slider
//            if isEditing {
//                Slider(value: scoreProxy, in: -2.0...2.0, step: 1.0)
//                    .padding(.vertical, 4)
//            }
            
            // MARK: Tags
            if isEditing {
                FlowLayout {
                    // show all tag with selected tags first
                    let sortedTags = tags.sorted {
                        if tagSet.contains($0.name)
                            && tagSet.contains($1.name)
                        {
                            return $0.name < $1.name
                        } else if tagSet.contains($0.name) {
                            return true
                        } else if tagSet.contains($1.name) {
                            return false
                        } else {
                            return $0.name < $1.name
                        }
                    }
                    
                    ForEach(sortedTags) { tag in
                        TagChipView(
                            label: tag.name,
                            style: .selectable(
                                isSelected: tagSet.contains(tag.name),
                                onTap: {
                                    let newTags =
                                    tagSet.symmetricDifference([
                                        tag.name
                                    ])
                                    logEntry.tagsRaw = newTags.sorted()
                                        .joined(separator: ",")
                                }
                            )
                        )
                    }
                }
                
                TextField("New Tag", text: $newTag)
                    .submitLabel(.done)
                    .onSubmit {
                        addCustomTag()
                        showNewTagField = false
                        focused.wrappedValue = .log(
                            timestamp: logEntry.timestamp
                        )
                    }
                    .focused(
                        focused,
                        equals: .tagField(timestamp: logEntry.timestamp)
                    )
                    .padding(.top, 4)
            } else {
                // show only selected tags for entry
                FlowLayout {
                    ForEach(logEntry.tags, id: \.self) { tag in
                        TagChipView(
                            label: tag,
                            style: .display
                        )
                    }
                }
                
            }
            
            // MARK: Address
            if let address = logEntry.address {
                HStack(alignment: .top) {
                    Button {
                        logEntry.address = nil
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.caption)
                    }
                    .disabled(!isEditing)
                    
                    Text(address)
                        .font(.caption)
                }
                .padding(.top, 8)
            } else {
                if isEditing {
                    Button {
                        locationManager.setItem = self.setItem
                        locationManager.requestLocation()
                    } label: {
                        Image(systemName: "location.slash.fill")
                            .font(.caption)
                    }
                    .padding(.top, 8)
                }
            }
            

            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassTintedCard(
            color: Theme.named(themeName).color(for: logEntry.score),
            interactive: !isEditing // disable when editing
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                focused.wrappedValue = .log(timestamp: logEntry.timestamp)
            }
        }
        .overlay(alignment: .bottom) {
            // Stable anchor for scrolling
            Color.clear.frame(height: 0)
                .id(logEntry.timestamp)
        }

    }
}

#Preview {
    @Previewable @FocusState var isFocused: InlineFocusField?
    let entry = DailyLogEntry(timestamp: .now, log: "Great day!", score: 2)
    InlineLogEntryView(logEntry: entry, focused: $isFocused)
}
