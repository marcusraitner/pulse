//
//  Theme.swift
//  Pulse
//
//  Created by Marcus Raitner on 27.03.26.
//

import Foundation
import SwiftUI

/// A color theme that maps the five score levels (−2 to +2) to distinct colors.
/// Built-in presets are available via the static constants on the extension below.
struct Theme: Identifiable {
    var id: String
    var name: String
    var minus2: Color
    var minus1: Color
    var neutral: Color
    var plus1: Color
    var plus2: Color

    /// Returns the theme color for `score`, clamping unknown values to `neutral`.
    func color(for score: Int) -> Color {
        switch score {
        case -2: return minus2
        case -1: return minus1
        case 0:  return neutral
        case 1:  return plus1
        case 2:  return plus2
        default: return neutral
        }
    }
    
    /// Returns a gradient derived from the color mapped to the nearest integer score.
    func gradient(for score: CGFloat) -> AnyGradient {
        return color(for: Int(round(score))).gradient
    }
}

extension Theme {
    static let pastel: Theme = .init(
        id: "default",
        name: "Default",
        minus2: Color("default/minus2"),
        minus1: Color("default/minus1"),
        neutral: Color("default/neutral"),
        plus1: Color("default/plus1"),
        plus2: Color("default/plus2"))
    
    static let sea: Theme = .init(
        id: "sea",
        name: "Sea",
        minus2: Color("sea/minus2"),
        minus1: Color("sea/minus1"),
        neutral: Color("sea/neutral"),
        plus1: Color("sea/plus1"),
        plus2: Color("sea/plus2"))

    static let tropical: Theme = .init(
        id: "tropical",
        name: "Tropical",
        minus2: Color("tropical/minus2"),
        minus1: Color("tropical/minus1"),
        neutral: Color("tropical/neutral"),
        plus1: Color("tropical/plus1"),
        plus2: Color("tropical/plus2"))
    
    static let traffic: Theme = .init(
        id: "traffic",
        name: "Traffic",
        minus2: Color("traffic/minus2"),
        minus1: Color("traffic/minus1"),
        neutral: Color("traffic/neutral"),
        plus1: Color("traffic/plus1"),
        plus2: Color("traffic/plus2"))

    /// All built-in theme presets shown in Settings.
    static let builtIn: [Theme] = [.pastel, .sea, .tropical, .traffic]

    /// Returns the built-in theme whose `id` matches `id`, falling back to `.default`.
    static func named(_ id: String) -> Theme {
        builtIn.first { $0.id == id } ?? .pastel
    }
}
