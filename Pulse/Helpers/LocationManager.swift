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

/// Wraps CoreLocation permission requests and one-shot coordinate capture.
/// Once a location fix is obtained it is automatically reverse-geocoded via `Compat.reverseGeocode`.
/// Consumers react to new locations by assigning a closure to `setItem`.
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "LocationManager")

    /// Called with the first `MKMapItem` whenever reverse geocoding produces a result.
    var setItem: (MKMapItem) -> Void = { _ in }

    /// The most recently obtained device location.
    @Published var location: CLLocation?

    /// Reverse-geocoded map items for the current location.
    /// Setting this property automatically calls `setItem` with the first result.
    @Published var mapItems: [MKMapItem] = [] {
        didSet {
            if let item = mapItems.first { setItem(item) }
        }
    }

    /// The current CoreLocation authorisation status.
    @Published var authorizationStatus: CLAuthorizationStatus
    
    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
    }
    
    /// Requests the user's location, prompting for authorisation if not yet determined.
    /// If permission is already granted, a one-shot location fix is requested immediately.
    func requestLocation() {
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
        self.authorizationStatus = manager.authorizationStatus
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
        
        guard let location = location else { return }
        
        Task { [weak self] in
            guard let self else { return }
            do {
                let items = try await Compat.reverseGeocode(location: location)
                await MainActor.run { self.mapItems = items }
            } catch {
                logger.error("Error reverse geocoding location: \(error.localizedDescription)")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("\(error.localizedDescription)")
    }
}

