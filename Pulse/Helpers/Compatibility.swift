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
        if #available(iOS 26, *) {
            self.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
    
    @ViewBuilder
    func glassBackground(cornerRadius: CGFloat = 10) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.clear, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    /// Glass capsule for pill-shaped buttons. Falls back to ultraThinMaterial in a Capsule.
    @ViewBuilder
    func glassCapsule() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.clear, in: Capsule())
        } else {
            self.background(.ultraThinMaterial, in: Capsule())
        }
    }

    /// Glass circle for floating action buttons. Falls back to regularMaterial with a white glow shadow.
    @ViewBuilder
    func glassCircle() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular, in: Circle())
        } else {
            self.background(.regularMaterial, in: Circle())
        }
    }

    /// Tinted interactive glass card keyed to a score color. Falls back to light ultraThinMaterial with a semi-transparent color overlay.
    @ViewBuilder
    func glassTintedCard(color: Color, cornerRadius: CGFloat = 10) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular.tint(color.opacity(0.45)).interactive(), in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            self.background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(color.opacity(0.45))
                    }
            }
        }
    }
}

// MARK: - Toolbar button roles

enum Compat {
    /// Confirm toolbar button. Uses `.confirm` role on iOS 26+, falls back to a labelled button.
    @ViewBuilder
    static func confirmButton(_ label: String = String(localized: "Done"), action: @escaping () -> Void) -> some View {
        if #available(iOS 26, *) {
            Button(role: .confirm, action: action)
        } else {
            Button(label, action: action)
        }
    }

    /// Cancel/close toolbar button. Uses `.close` role on iOS 26+, falls back to a labelled button.
    @ViewBuilder
    static func closeButton(_ label: String = String(localized: "Cancel"), action: @escaping () -> Void) -> some View {
        if #available(iOS 26, *) {
            Button(role: .close, action: action)
        } else {
            Button(label, role: .cancel, action: action)
        }
    }

    // MARK: - MKMapItem API

    /// Returns the coordinate for a map item using the iOS 26 API where available.
    static func coordinate(from item: MKMapItem) -> CLLocationCoordinate2D {
        if #available(iOS 26, *) {
            return item.location.coordinate
        } else {
            return item.placemark.coordinate
        }
    }

    /// Returns a single-line address string for a map item.
    static func address(from item: MKMapItem) -> String {
        if #available(iOS 26, *) {
            return item.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true) ?? "Unknown"
        } else {
            return item.placemark.name ?? "Unknown"
        }
    }

    // MARK: - Reverse geocoding

    /// Reverse-geocodes a location to map items.
    /// Uses MKReverseGeocodingRequest on iOS 26+, CLGeocoder on earlier versions.
    static func reverseGeocode(location: CLLocation) async throws -> [MKMapItem] {
        if #available(iOS 26, *) {
            guard let request = MKReverseGeocodingRequest(location: location) else { return [] }
            return try await request.mapItems
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let items = (placemarks ?? []).map { MKMapItem(placemark: MKPlacemark(placemark: $0)) }
                    continuation.resume(returning: items)
                }
            }
        }
    }
}
