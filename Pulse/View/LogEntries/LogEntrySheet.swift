//
//  NewLogEntrySheet.swift
//  Pulse
//
//  Created by Marcus Raitner on 21.02.26.
//

import SwiftUI
import OSLog
import SwiftData
import CoreLocation
import CoreLocationUI
import MapKit

struct LogEntrySheet: View {
    // This holds the temporary values of the sheet; initialized in a task to entry
    @State private var newEntry: DailyLogEntry = DailyLogEntry(timestamp: .now, log: "", score: 0)
    // The entry to edit (if passed at all; otherwise defaults to the above values (see init)
    @Binding var entry: DailyLogEntry
    // Determines whether sheet is shown for a new entry or an existing
    @Binding var isEntryNew: Bool
    // used to manage validation; showing the validation message only if stepper was touched
    @State private var isNew = true
    @State private var isPresentingConfirm = false
    @State private var storeLocations: Bool = false

    @AppStorage(AppStorageKeys.freezeHistory) private var freezeHistory: Bool = true

    private var isEntryEditable: Bool {
        !freezeHistory || Calendar.current.isDateInToday(entry.timestamp)
    }
    
    // closure gets called on save with the values in newEntry
    var saveEntry: (DailyLogEntry) -> Void
    
    @StateObject var locationManager = LocationManager()
    @State private var mapPosition: MapCameraPosition = .automatic
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private let logger = Logger(subsystem: "de.raitner.pulse", category: "NewLogEntrySheet")

    init(entry: Binding<DailyLogEntry> = .constant(DailyLogEntry(timestamp: .now, log: "", score: 0)),
         isEntryNew: Binding<Bool> = .constant(true), saveEntry: @escaping (DailyLogEntry) -> Void) {
        self._entry = entry
        self._isEntryNew = isEntryNew
        self.saveEntry = saveEntry
    }
    
    private func setItem(item: MKMapItem) -> Void {
        var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
        
        coordinate = Compat.coordinate(from: item)

        newEntry.latitude = coordinate.latitude
        newEntry.longitude = coordinate.longitude

        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        mapPosition = .region(region)

        newEntry.address = Compat.address(from: item)
    }
    
    var body: some View {
        Form {
            Section {
                if isEntryEditable {
                    VStack(alignment: .leading) {
                        TextField("What's going on?", text: $newEntry.log, axis: .vertical)
                            .multilineTextAlignment(.leading)
                            .lineLimit(5...Int.max)
                        
                        Text("Please capture your moment here.")
                            .font(.caption)
                            .foregroundStyle(!isNew && newEntry.log.isEmpty ? .red : .clear)
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
                            ScoreLabelView(score: newEntry.score, style: .outlined)
                            Stepper("", value: $newEntry.score, in: -2...2, step: 1)
                                .labelsHidden()
                                .padding(.top, 4)
                        }
                        .padding(.leading)
                    }
                } else {
                    HStack (alignment: .top) {
                        Text("\(entry.log)")
                        Spacer()
                        ScoreLabelView(score: entry.score, style: .outlined)
                    }
                }
                
                HStack {
                    Text("Recorded at")
                    Spacer()
                    Text("\(entry.timestamp.formatted(date: .numeric, time: .shortened))")
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
                                    Text("\(newEntry.address ?? "Unknown")")
                                    
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
                        if let address = entry.address {
                            Label("\(address)", systemImage: "location.circle.fill")
                                .labelStyle(.titleAndIcon)
                            
                            if let latitude = entry.latitude, let longitude = entry.longitude {
                                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                let region = MKCoordinateRegion(
                                    center: coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // ~1–2 km depending on latitude
                                )
                                
                                Map(position: .constant(.region(region))) {
                                    Marker("\(address)", coordinate: CLLocationCoordinate2D(latitude: entry.latitude ?? 0, longitude: entry.longitude ?? 0))
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
            .onChange(of: storeLocations) {
                if storeLocations {
                    locationManager.setItem = self.setItem
                    locationManager.requestLocation()
                }
            }
            
            Section {
                HStack {
                    Spacer()
                    if !isEntryNew && isEntryEditable {
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
                                context.delete(entry)
                                context.saveOrLog("Failure saving deleted entry", logger: logger)
                                dismiss()
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
        .task {
            newEntry = DailyLogEntry(timestamp: .now, log: entry.log, score: entry.score)
        }
        .onChange(of: newEntry.score) {
            isNew = false
        }
        .navigationTitle(isEntryNew ? "New Moment" : isEntryEditable ? "Edit Moment" : "View Moment")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Compat.confirmButton(String(localized: "Save")) {
                    saveEntry(newEntry)
                    dismiss()
                }
                .disabled(newEntry.log.isEmpty)
            }
            ToolbarItem(placement: .cancellationAction) {
                Compat.closeButton { dismiss() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LogEntrySheet() { entry in }
    }
}
