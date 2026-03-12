//
//  LocationManager.swift
//  Pulse
//
//  Created by Marcus Raitner on 10.03.26.
//

import Foundation
import MapKit
import CoreLocation
import OSLog
internal import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "ContentView")
    var setItem: (MKMapItem) -> Void = { _ in }
    
    @Published var location: CLLocation?
    @Published var mapItems: [MKMapItem] = [] {
        didSet {
            if let item = mapItems.first { setItem(item) }
        }
    }
    
    @Published var authorizationStatus: CLAuthorizationStatus
    
    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
    }
    
    func requestLocation() {
        print(#function)
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print(#function)
        self.authorizationStatus = manager.authorizationStatus
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(#function)
        location = locations.first
        
        guard let location = location else { return }
        
        if #available(iOS 26.0, *) {
            // Bridge into async context from delegate callback
            Task { [weak self] in
                guard let self else { return }
                if let request = MKReverseGeocodingRequest(location: location) {
                    do {
                        let items = try await request.mapItems
                        // Publish on main actor to update @Published safely
                        await MainActor.run {
                            self.mapItems = items
                        }
                    } catch {
                        print("Error reverse geocoding location: \(error)")
                    }
                }
            }
        } else {
            // Fallback on earlier versions: use CLGeocoder
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                guard let self else { return }
                if let error = error {
                    print("Error reverse geocoding location: \(error)")
                    return
                }
                let items: [MKMapItem] = (placemarks ?? []).map { placemark in
                    let mkPlacemark = MKPlacemark(placemark: placemark)
                    return MKMapItem(placemark: mkPlacemark)
                }
                DispatchQueue.main.async {
                    self.mapItems = items
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(#function)
        logger.error("\(error.localizedDescription)")
    }
}

