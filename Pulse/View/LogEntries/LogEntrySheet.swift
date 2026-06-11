//
//  LogEntrySheet.swift
//  Pulse
//
//  Created by Marcus Raitner on 21.02.26.
//

import SwiftUI
import OSLog
import SwiftData
import CoreLocation
import MapKit

/// Modal sheet for creating a new log entry or viewing/editing an existing one.
///
/// Pass `entry` to open an existing entry for editing. Omit it (or pass `nil`)
/// to open a blank new-entry form. Saves directly to the SwiftData context on confirm.
struct LogEntrySheet: View {
    
    let day: DailyEntry
    let entry: DailyLogEntry?
    let isModalPresented: Bool
    
    init(day: DailyEntry, entry: DailyLogEntry? = nil, isModal: Bool = true) {
        self.day = day
        self.entry = entry
        _log = State(initialValue: entry?.log ?? "")
        _score = State(initialValue: entry?.score ?? 0)
        _latitude = State(initialValue: entry?.latitude)
        _longitude = State(initialValue: entry?.longitude)
        _address = State(initialValue: entry?.address)
        _timestamp = State(initialValue: entry?.timestamp ?? .now)
        _entryTags = State(initialValue: .init(entry?.tags ?? []) )
        isModalPresented = isModal
    }

    private var isEntryNew: Bool { entry == nil }

    @Query private var tags: [Tag]
    
    @State private var log: String
    @State private var score: Int
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var address: String?
    @State private var entryTags: Set = Set<String>()
    @State private var newTag: String = ""
    @State private var timestamp: Date = .now

    
    // Controlling Focus
    enum FocusedField {
        case log, newTag, score, timestamp
    }
    
    @FocusState private var focusedField: FocusedField?
    
    // used to manage validation; showing the validation message only if stepper was touched
    @State private var isNew = true
    @State private var isPresentingConfirm = false
    @State private var storeLocations: Bool = false

    @AppStorage(AppStorageKeys.enableEditingHistory) private var enableEditingHistory: Bool = true

    private var isEntryEditable: Bool {
        enableEditingHistory || Calendar.current.isDateInToday(entry?.timestamp ?? .now)
    }
    
    @State var locationManager = LocationManager()
    @State private var mapPosition: MapCameraPosition = .automatic
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private var allTags: [String] {
       tags.map(\.name)
    }
    
    private var rawTags: String {
        entryTags.joined(separator: ",")
    }

    private var sanitizedNewTag: String {
        newTag.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
    }

    private var isNewTagValid: Bool {
        let name = sanitizedNewTag
        guard !name.isEmpty else { return false }
        return !tags.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })
    }
    
    private func addCustomTag() {
        // Button calling this is checking isNewTagValid before, but let's make it explicit
        guard isNewTagValid else { return }
        let name = sanitizedNewTag
        context.insert(Tag(name: name))
        context.saveOrLog("Failed to save tag", logger: logger)
        entryTags.insert(name)
        newTag = ""
    }
    
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "LogEntrySheet")

    /// Updates the location state with the coordinate and reverse-geocoded address from `item`.
    private func setItem(item: MKMapItem) -> Void {
        var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
        
        coordinate = Compat.coordinate(from: item)

        latitude = coordinate.latitude
        longitude = coordinate.longitude

        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        mapPosition = .region(region)

        address = Compat.address(from: item)
    }
    
    private func save() {
        if let entry {
            entry.log = log
            entry.score = score
            entry.tagsRaw = rawTags
            entry.timestamp = timestamp
            context.saveOrLog("Failure while saving entry", logger: logger)
        } else {
            // new entry
            let newEntry = DailyLogEntry(
                timestamp: timestamp,
                log: log,
                score: score,
                entry: day,
                latitude: storeLocations ? latitude : nil,
                longitude: storeLocations ? longitude : nil,
                address: storeLocations ? address : nil,
                tagsRaw: rawTags
            )
            context.insert(newEntry)
            context.saveOrLog("Failure saving new entry", logger: logger)
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text(timestamp.formatted(date: .complete, time: .shortened))) {
                if isEntryEditable {
                    VStack(alignment: .leading) {
                        TextField("What's going on?", text: $log, axis: .vertical)
                            .multilineTextAlignment(.leading)
                            .lineLimit(5...Int.max)
                            .focused($focusedField, equals: .log)
                        
                        Text("Please capture your moment here.")
                            .font(.caption)
                            .foregroundStyle(!isNew && log.isEmpty ? .red : .clear)
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
                            ScoreLabelView(score: score, style: .outlined)
                            Stepper("", value: $score, in: -2...2, step: 1)
                                .labelsHidden()
                                .padding(.top, 4)
                                .focused($focusedField, equals: .score)
                        }
                        .padding(.leading)
                    }
                } else {
                    HStack (alignment: .top) {
                        Text(log)
                        Spacer()
                        ScoreLabelView(score: score, style: .outlined)
                    }
                }
                
                // MARK: - Tags
                VStack {
                    FlowLayout {
                        ForEach(isEntryEditable ? allTags : entry?.tags ?? [], id: \.self) { tag in
                            if isEntryEditable {
                                TagChipView(label: tag, style: .selectable(isSelected: entryTags.contains(tag), onTap: { if entryTags.contains(tag) { entryTags.remove(tag) } else { entryTags.insert(tag) } } ))
                            } else {
                                TagChipView(label: tag, style: .display)
                            }
                        }
                    }
                    if isEntryEditable {
                        HStack {
                            TextField("New Tag", text: $newTag)
                                .submitLabel(.done)
                                .onSubmit {
                                    addCustomTag()
                                }
                                .focused($focusedField, equals: .newTag)
                            Button("Add") {
                                addCustomTag()
                            }
                            .buttonStyle(.bordered)
                            .disabled(!isNewTagValid)
                        }
                        .padding(.top, 4)
                    }
                }
                
                HStack {
                    if isEntryEditable {
                        DatePicker(timestamp.formatted(date: .abbreviated, time: .omitted), selection: $timestamp, in: .init(uncheckedBounds: (.distantPast, .now)), displayedComponents: .hourAndMinute)
                            .focused($focusedField, equals: .timestamp)
                    } else {
                        Text("Recorded at")
                        Spacer()
                        Text((entry?.timestamp ?? .now).formatted(date: .numeric, time: .shortened))
                    }
                }
                
                VStack(alignment: .leading) {
                    if isEntryNew {
                        Toggle(isOn: $storeLocations) {
                            Text("Store location")
                        }
                        
                        if storeLocations {
                            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                                Text("Location services are disabled. Please open settings to enable location services.")
                                
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    Button("Open Settings") {
                                        UIApplication.shared.open(url)
                                    }
                                    .listRowSeparator(.hidden)
                                }
                            } else {
                                if let item = locationManager.mapItems.first {
                                    Text(address ?? "Unknown")
                                    
                                    Map(position: $mapPosition) {
                                        Marker(item: item)
                                    }
                                    .frame(height: 300)
                                    .mapStyle(.standard(elevation: .realistic))
                                    .mapControls {
                                        MapUserLocationButton()
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 300)
                                        .overlay {
                                            VStack {
                                                ProgressView()
                                                Text("No location available")
                                            }
                                            .foregroundStyle(.primary)
                                        }
                                }
                            }
                        }
                        
                    } else {
                        if let address {
                            Label(address, systemImage: "location.circle.fill")
                                .labelStyle(.titleAndIcon)
                            
                            if let latitude, let longitude {
                                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                let region = MKCoordinateRegion(
                                    center: coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // ~1–2 km depending on latitude
                                )
                                
                                Map(position: .constant(.region(region))) {
                                    Marker(address, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                                }
                                .mapControls {
                                    MapScaleView()
                                }
                                .frame(height: 300)
                            }
                        } else {
                            Text("No location available")
                        }
                    }
                }
            }
            .headerProminence(.increased)
            .onChange(of: storeLocations) {
                if storeLocations {
                    locationManager.setItem = self.setItem
                    locationManager.requestLocation()
                }
            }
            
            Section {
                HStack {
                    Spacer()
                    if isEntryEditable {
                        Button(role: .destructive) {
                            isPresentingConfirm = true
                        } label: {
                            Label("Delete Moment", systemImage: "trash")
                                .labelStyle(.titleAndIcon)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.automatic)
                        .confirmationDialog("Are you sure?",
                                            isPresented: $isPresentingConfirm,
                                            titleVisibility: .visible) {
                            Button("Delete", role: .destructive) {
                                if let entry {
                                    context.delete(entry)
                                    context.saveOrLog("Failure saving deleted entry", logger: logger)
                                    dismiss()
                                }
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
        .onChange(of: score) {
            isNew = false
        }
        .onAppear {
            focusedField = .log
        }
        .navigationTitle(isEntryNew ? "New Moment" : isEntryEditable ? "Edit Moment" : "View Moment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Compat.confirmButton(String(localized: "Save")) {
                    save()
                    dismiss()
                }
                .disabled(log.isEmpty)
            }
            if isModalPresented {
                ToolbarItem(placement: .cancellationAction) {
                    Compat.closeButton { dismiss() }
                }
            }
        }
    }
}

#Preview("Neu") {
    NavigationStack {
        LogEntrySheet(day: .init(date: .now))
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.dark)
    }
}

#Preview("Alt") {
    NavigationStack {
        LogEntrySheet(day: .init(date: .now), entry: .init(timestamp: .now, log: "Test", score: -2))
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.dark)
    }
}
