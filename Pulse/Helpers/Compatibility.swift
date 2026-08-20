//
//  Compatibility.swift
//  Pulse
//
//  Created by Marcus Raitner on 26.03.26.
//
//  Single source of truth for every iOS 26 API divergence.
//  All #available(iOS 26, *) checks live here; call sites use the wrappers.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Glass / Material view modifiers

extension View {
    /// Interactive glass card (rounded rect). Falls back to ultraThinMaterial.
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = 10) -> some View {
        self.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    @ViewBuilder
    func glassBackground(cornerRadius: CGFloat = 10) -> some View {
        self.glassEffect(.clear, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    /// Glass capsule for pill-shaped buttons. Falls back to ultraThinMaterial in a Capsule.
    @ViewBuilder
    func glassCapsule() -> some View {
        self.glassEffect(.clear, in: Capsule())
    }
    
    /// Glass circle for floating action buttons. Falls back to regularMaterial with a white glow shadow.
    @ViewBuilder
    func glassCircle() -> some View {
        self.glassEffect(.regular, in: Circle())
    }

    /// Tinted interactive glass card keyed to a score color. Falls back to light ultraThinMaterial with a semi-transparent color overlay.
    @ViewBuilder
    func glassTintedCard(color: Color, cornerRadius: CGFloat = 10) -> some View {
        self.glassEffect(.regular.tint(color.opacity(0.45)).interactive(), in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Toolbar button roles

enum Compat {
    /// Confirm toolbar button. Uses `.confirm` role on iOS 26+, falls back to a labelled button.
    @ViewBuilder
    static func confirmButton(_ label: String = String(localized: "Done"), action: @escaping () -> Void) -> some View {
        Button(role: .confirm, action: action)
    }
    
    /// Cancel/close toolbar button. Uses `.close` role on iOS 26+, falls back to a labelled button.
    @ViewBuilder
    static func closeButton(_ label: String = String(localized: "Cancel"), action: @escaping () -> Void) -> some View {
        Button(role: .close, action: action)
    }
    
    // MARK: - MKMapItem API
    
    /// Returns the coordinate for a map item using the iOS 26 API where available.
    static func coordinate(from item: MKMapItem) -> CLLocationCoordinate2D {
        return item.location.coordinate
    }
    
    /// Returns a single-line address string for a map item.
    static func address(from item: MKMapItem) -> String {
        return item.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true) ?? "Unknown"
    }
    
    // MARK: - Reverse geocoding
    
    /// Reverse-geocodes a location to map items.
    /// Uses MKReverseGeocodingRequest on iOS 26+, CLGeocoder on earlier versions.
    static func reverseGeocode(location: CLLocation) async throws -> [MKMapItem] {
        guard let request = MKReverseGeocodingRequest(location: location) else { return [] }
        return try await request.mapItems
    }
}
