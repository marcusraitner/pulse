//
//  ScoreStyleHelper.swift
//  collins score
//
//  Created by Marcus Raitner on 29.01.26.
//

import Foundation
import SwiftUI

struct ScoreStyleHelper {
    static func color(for score: Int) -> Color {
        switch score {
        case -2: return .minus2
        case -1: return .minus1
        case 0:  return .neutral
        case 1:  return .plus1
        case 2:  return .plus2
        default: return .neutral
        }
    }
    
    static func gradient(for score: CGFloat) -> AnyGradient {
        return color(for: Int(round(score))).gradient
    }
    
    let gradient = Gradient(colors: [.minus2, .minus1, .neutral, .plus1, .plus2])
}
