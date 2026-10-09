//
//  CachedInsights.swift
//  Pulse
//
//  Created by Marcus Raitner on 09.10.26.
//

import Foundation

struct CachedInsights: Codable {
    var greatMoments: [String]
    var poorMoments: [String]
    var actionableTips: [String]
    var createdAt: Date
    var windowDays: Int = 0 // 0 = all time; default preserves backward compatibility
}
