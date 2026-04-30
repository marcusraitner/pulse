//
//  FeatureFlags.swift
//  Pulse
//
//  Created by Marcus Raitner on 18.02.26.
//

import Foundation
import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif

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
    /// `true` when Apple Intelligence (`SystemLanguageModel`) is available on this device.
    public let foundationModelsAvailable: Bool

    /// Creates feature flags. `iOS26` and `foundationModelsAvailable` are derived automatically from system availability.
    init(editHistory: Bool = false, adminEnabled: Bool = false) {
        self.editHistory = editHistory
        self.adminEnabled = adminEnabled

        if #available(iOS 26, *) {
            iOS26 = true
            foundationModelsAvailable = SystemLanguageModel.default.availability == .available
        } else {
            iOS26 = false
            foundationModelsAvailable = false
        }
    }
}

extension EnvironmentValues {
    @Entry public var featureFlags = FeatureFlags(editHistory: false, adminEnabled: false)
}
