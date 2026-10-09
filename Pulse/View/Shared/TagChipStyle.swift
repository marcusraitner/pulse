//
//  TagChipStyle.swift
//  Pulse
//
//  Created by Marcus Raitner on 09.10.26.
//

import Foundation

enum TagChipStyle {
    case display
    case selectable(isSelected: Bool, onTap: () -> Void)
}
