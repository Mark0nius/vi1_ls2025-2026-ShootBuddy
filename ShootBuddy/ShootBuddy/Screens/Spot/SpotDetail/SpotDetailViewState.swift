//
//  SpotDetailViewState.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 15.06.2026.
//
import SwiftUI

@Observable
class SpotDetailViewState {
    var spot: Spot
    var weather: WeatherCode?
    var refreshID: UUID = UUID()  // Used to force view refresh

    init(spot: Spot) {
        self.spot = spot
    }
}
