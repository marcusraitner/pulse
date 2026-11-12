//
//  MomentLocation.swift
//  Pulse
//
//  Created by Marcus Raitner on 06.11.26.
//

import Foundation
import CoreLocation

/// The place where a moment was captured.
///
/// Bundles the three location fields of `DailyLogEntry` so they are always
/// read and written together and never end up half-set.
nonisolated struct MomentLocation: Equatable {
    var latitude: Double
    var longitude: Double
    var address: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Short coordinate text, used as address until (or if) reverse geocoding finds one.
    var formattedCoordinate: String {
        let format = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(4))
        return "\(latitude.formatted(format)), \(longitude.formatted(format))"
    }
}

extension MomentLocation {
    init(coordinate: CLLocationCoordinate2D, address: String? = nil) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude, address: address)
    }
}

extension DailyLogEntry {
    /// The moment's location, or `nil` if it has no coordinates.
    /// Setting `nil` clears coordinates and address.
    var location: MomentLocation? {
        get {
            guard let latitude, let longitude else { return nil }
            return MomentLocation(latitude: latitude, longitude: longitude, address: address)
        }
        set {
            latitude = newValue?.latitude
            longitude = newValue?.longitude
            address = newValue?.address
        }
    }
}
