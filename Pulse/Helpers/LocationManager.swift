//
//  LocationManager.swift
//  Pulse
//
//  Created by Marcus Raitner on 10.03.26.
//

import Foundation
import CoreLocation
import OSLog
internal import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    private let logger = Logger(subsystem: "de.raitner.pulse", category: "ContentView")
    
    @Published var location: CLLocationCoordinate2D?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first?.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("\(error.localizedDescription)")
    }
}
