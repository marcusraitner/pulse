//
//  FeatureFlags.swift
//  Pulse
//
//  Created by Marcus Raitner on 18.02.26.
//

import Foundation
import SwiftUI
import FoundationModels

/// Feature flags controlling optional or experimental functionality.
/// Injected into the SwiftUI environment via `\.featureFlags`.
public struct FeatureFlags: Sendable, Decodable {
    /// `true` when Apple Intelligence (`SystemLanguageModel`) is available on this device.
    public let foundationModelsAvailable: Bool

    /// Creates feature flags. `foundationModelsAvailable` is derived automatically from system availability.
    init() {
        foundationModelsAvailable = SystemLanguageModel.default.availability == .available
    }
}

extension EnvironmentValues {
    @Entry public var featureFlags = FeatureFlags()
}
