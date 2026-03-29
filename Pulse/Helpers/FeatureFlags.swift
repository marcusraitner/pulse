//
//  FeatureFlags.swift
//  Pulse
//
//  Created by Marcus Raitner on 18.02.26.
//

import Foundation
import SwiftUI

/// Feature flags controlling optional or experimental functionality.
/// Injected into the SwiftUI environment via `\.featureFlags`.
/// `iOS26` is derived automatically at runtime from system availability.
public struct FeatureFlags: Sendable, Decodable {
    /// Allows editing log entries from previous days.
    public let editHistory: Bool
    /// Enables admin-only UI controls such as the delete-entry button.
    public let adminEnabled: Bool
    /// `true` when running on iOS 26 or later; set automatically at init.
    public let iOS26: Bool

    /// Creates feature flags. `iOS26` is derived automatically from system availability.
    init(editHistory: Bool = false, adminEnabled: Bool = false) {
        self.editHistory = editHistory
        self.adminEnabled = adminEnabled
        
        if #available(iOS 26, *) {
            iOS26 = true
        } else {
            iOS26 = false
        }

    }
}

extension EnvironmentValues {
    @Entry public var featureFlags = FeatureFlags(editHistory: false, adminEnabled: false)
}
