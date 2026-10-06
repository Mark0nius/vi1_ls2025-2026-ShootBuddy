//
//  SpotViewState.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//
import SwiftUI

@Observable
class SpotViewState {
    var spots: [Spot] = []
    var searchText: String = ""
    var selectedLightFilters: Set<LightType> = []
    var refreshID: UUID = UUID()  // Force view refresh
}
