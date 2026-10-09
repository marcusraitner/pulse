//
//  FilterState.swift
//  Pulse
//
//  Created by Marcus Raitner on 09.10.26.
//

import Observation

@Observable
final class FilterState {
    var selectedTag: String? = nil
    var isFilterActive: Bool = false
    var activeFilter: String? { isFilterActive ? selectedTag : nil }
}
