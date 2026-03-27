//
//  ScoreStyleHelper.swift
//  collins score
//
//  Created by Marcus Raitner on 29.01.26.
//

import Foundation
import SwiftUI

/// Maps score values (−2 to +2) to theme-aware colors and gradients.
/// Colors are resolved from the asset catalog under a folder named after the theme.
struct ScoreStyleHelper {
    /// Returns the color for an integer score within the given theme.
    /// - Parameters:
    ///   - score: An integer in the range −2...+2.
    ///   - themeName: Asset catalog theme folder name. Defaults to `"default"`.
    static func color(for score: Int, themeName: String? = nil) -> Color {
        let theme: String = themeName ?? "default"
        
        switch score {
        case -2: return Color("\(theme)/minus2")
        case -1: return Color("\(theme)/minus1")
        case 0:  return Color("\(theme)/neutral")
        case 1:  return Color("\(theme)/plus1")
        case 2:  return Color("\(theme)/plus2")
        default: return Color("\(theme)/neutral")
        }
    }
    
    /// Returns a gradient derived from the color for a fractional score.
    /// The score is rounded to the nearest integer before color lookup.
    /// - Parameters:
    ///   - score: A `CGFloat` score, typically the average of a day's log entries.
    ///   - themeName: Asset catalog theme folder name. Defaults to `"default"`.
    static func gradient(for score: CGFloat, themeName: String? = nil) -> AnyGradient {
        return color(for: Int(round(score)), themeName: themeName).gradient
    }
}
