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
    public let enableRemovingEntries: Bool
    
    init(editHistory: Bool = false, enableRemovingEntries: Bool = false) {
        self.editHistory = editHistory
        self.enableRemovingEntries = enableRemovingEntries
    }
}

extension EnvironmentValues {
    @Entry public var featureFlags = FeatureFlags(editHistory: false, enableRemovingEntries: false)
}
