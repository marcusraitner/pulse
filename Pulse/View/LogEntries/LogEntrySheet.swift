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
        _location = State(initialValue: entry?.location)
        if let location = entry?.location {
            _mapPosition = State(initialValue: .region(Self.region(around: location.coordinate)))
        }
        if let entry {
            _timestamp = State(initialValue: entry.timestamp)
        } else {
            // this is an entry on a past day: we use hour and minute of now
            var dayComponents = Calendar.current.dateComponents([.year, .month, .day], from: day.date)
            let hourMinutes = Calendar.current.dateComponents([.hour, .minute], from: .now)
            dayComponents.hour = hourMinutes.hour
            dayComponents.minute = hourMinutes.minute
            
            // if no matching date is found (unlikely) we default to the timestamp of the day
            _timestamp = State(initialValue: Calendar.current.date(from: dayComponents) ?? day.date)
        }
        _entryTags = State(initialValue: .init(entry?.tags ?? []) )
        isModalPresented = isModal
    }

    private var isEntryNew: Bool { entry == nil }

    @Query private var tags: [Tag]
    
    @State private var log: String
    @State private var score: Int
    @State private var location: MomentLocation?
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
    @State private var mapPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var geocodeTask: Task<Void, Never>?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private var allTags: [String] {
       tags.map(\.name).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
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
        let coordinate: CLLocationCoordinate2D = item.location.coordinate
        geocodeTask?.cancel()
        mapPosition = .region(Self.region(around: coordinate))

        location = MomentLocation(
            coordinate: coordinate,
            address: item.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true) ?? "Unknown"
        )
    }

    /// Sets the location to a coordinate the user tapped on the map.
    /// The coordinate text stands in as address until reverse geocoding returns;
    /// a newer tap cancels the lookup of an older one.
    private func selectLocation(at coordinate: CLLocationCoordinate2D) {
        let picked = MomentLocation(coordinate: coordinate)
        location = MomentLocation(coordinate: coordinate, address: picked.formattedCoordinate)

        geocodeTask?.cancel()
        geocodeTask = Task {
            guard let address = await locationManager.address(for: coordinate), !Task.isCancelled else { return }
            location?.address = address
        }
    }

    private func useCurrentLocation() {
        locationManager.setItem = self.setItem
        locationManager.requestLocation()
    }

    private func removeLocation() {
        geocodeTask?.cancel()
        location = nil
    }

    private static func region(around coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // ~1–2 km depending on latitude
        )
    }
    
    private func save() {
        if let entry {
            entry.log = log
            entry.score = score
            entry.tagsRaw = rawTags
            entry.timestamp = timestamp
            // only touch the location fields if they changed, to avoid needless CloudKit writes
            if entry.location != location {
                entry.location = location
            }
            context.saveOrLog("Failure while saving entry", logger: logger)
            HealthMoodLogger.save(entry)
        } else {
            // new entry
            let newEntry = DailyLogEntry(
                timestamp: timestamp,
                log: log,
                score: score,
                entry: day,
                tagsRaw: rawTags
            )
            newEntry.location = storeLocations ? location : nil
            context.insert(newEntry)
            context.saveOrLog("Failure saving new entry", logger: logger)
            HealthMoodLogger.save(newEntry)
        }
    }
    
    private var isLocationDenied: Bool {
        locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted
    }

    @ViewBuilder
    private var locationDeniedHint: some View {
        Text("Location services are disabled. Please open settings to enable location services.")

        if let url = URL(string: UIApplication.openSettingsURLString) {
            Button("Open Settings") {
                UIApplication.shared.open(url)
            }
            .listRowSeparator(.hidden)
        }
    }

    /// Location editor for an existing moment: tap the map to move the pin,
    /// use the current location, or remove the location entirely.
    @ViewBuilder
    private var editableLocation: some View {
        if let location {
            Label(location.address ?? location.formattedCoordinate, systemImage: "location.circle.fill")
                .labelStyle(.titleAndIcon)
        }

        MapReader { proxy in
            Map(position: $mapPosition) {
                if let location {
                    Marker(location.address ?? location.formattedCoordinate, coordinate: location.coordinate)
                }
            }
            .mapControls {
                MapScaleView()
            }
            .onTapGesture { point in
                if let coordinate = proxy.convert(point, from: .local) {
                    selectLocation(at: coordinate)
                }
            }
        }
        .frame(height: 300)

        Group {
            if location == nil {
                Text("Tap the map to set a location.")
            } else {
                Text("Tap the map to change the location.")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)

        if isLocationDenied {
            locationDeniedHint
        }

        VStack(alignment: .leading, spacing: 12) {
            Button("Use Current Location", systemImage: "location", action: useCurrentLocation)
                .disabled(isLocationDenied)
            if location != nil {
                Button(role: .destructive, action: removeLocation) {
                    // explicit red, otherwise the icon keeps the accent color (same as "Delete Moment")
                    Label("Remove Location", systemImage: "location.slash")
                        .foregroundStyle(.red)
                }
            }
        }
        // borderless keeps the two buttons separately tappable inside a Form row
        .buttonStyle(.borderless)
        .padding(.top, 12)
    }

    var body: some View {
        Form {
            Section() {
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
                            if isLocationDenied {
                                locationDeniedHint
                            } else {
                                if let item = locationManager.mapItems.first {
                                    Text(location?.address ?? "Unknown")
                                    
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
                        
                    } else if isEntryEditable {
                        editableLocation
                    } else {
                        if let location, let address = location.address {
                            Label(address, systemImage: "location.circle.fill")
                                .labelStyle(.titleAndIcon)

                            Map(position: .constant(.region(Self.region(around: location.coordinate)))) {
                                Marker(address, coordinate: location.coordinate)
                            }
                            .mapControls {
                                MapScaleView()
                            }
                            .frame(height: 300)
                        } else {
                            Text("No location available")
                        }
                    }
                }
            }
            .headerProminence(.standard)
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
                                    // read before deleting; the model is unusable afterwards
                                    let id = entry.id
                                    context.delete(entry)
                                    context.saveOrLog("Failure saving deleted entry", logger: logger)
                                    HealthMoodLogger.delete(id: id)
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
        .navigationTitle(timestamp.formatted(.dateTime.weekday().day().month().year().minute().hour()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) {
                    save()
                    dismiss()
                }
                .disabled(log.isEmpty)
            }
            if isModalPresented {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
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
