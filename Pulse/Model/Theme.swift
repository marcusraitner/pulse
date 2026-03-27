//
//  Theme.swift
//  Pulse
//
//  Created by Marcus Raitner on 27.03.26.
//

import Foundation
import SwiftUI

struct Theme: Identifiable {
    var id: String
    var name: String
    var minus2: Color
    var minus1: Color
    var neutral: Color
    var plus1: Color
    var plus2: Color
    
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
    
    func gradient(for score: CGFloat) -> AnyGradient {
        return color(for: Int(round(score))).gradient
    }
}

extension Theme {
    static let `default`: Theme = .init(
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
    
    static let builtIn: [Theme] = [.default, .sea, .tropical]
    
    static func named(_ id: String) -> Theme {
        builtIn.first { $0.id == id } ?? .default
    }
}
