//
//  FeatureFlags.swift
//  Pulse
//
//  Created by Marcus Raitner on 18.02.26.
//

import Foundation
import SwiftUI

public struct FeatureFlags: Sendable, Decodable {
    public let editHistory: Bool
    
    init(editHistory: Bool = false) {
        self.editHistory = editHistory
    }
}

extension EnvironmentValues {
    @Entry public var featureFlags = FeatureFlags(editHistory: false)
}
