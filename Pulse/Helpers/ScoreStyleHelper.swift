//
//  ScoreStyleHelper.swift
//  collins score
//
//  Created by Marcus Raitner on 29.01.26.
//

import Foundation
import SwiftUI
internal import Combine

struct ScoreStyleHelper {
    static func color(for score: Int, store: ThemeStore? = nil) -> Color {
        let theme: String = store?.themeName ?? "default"
        
        switch score {
        case -2: return Color("\(theme)/minus2")
        case -1: return Color("\(theme)/minus1")
        case 0:  return Color("\(theme)/neutral")
        case 1:  return Color("\(theme)/plus1")
        case 2:  return Color("\(theme)/plus2")
        default: return Color("\(theme)/neutral")
        }
    }
    
    static func gradient(for score: CGFloat, store: ThemeStore? = nil) -> AnyGradient {
        return color(for: Int(round(score)), store: store).gradient
    }
}

class ThemeStore: ObservableObject {
    @AppStorage("theme") var themeName: String = "default"
}
