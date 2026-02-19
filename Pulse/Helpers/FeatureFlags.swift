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
    public let adminEnabled: Bool
    public let iOS26: Bool
    
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
