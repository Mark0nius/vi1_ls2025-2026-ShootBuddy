//
//  SpotViewModel.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//
import SwiftUI

@Observable
class SpotViewModel {
    var state: SpotViewState = SpotViewState()
    private var dataManager: DataManaging

    init() {
        dataManager = DIContainer.shared.resolve()
    }

    func fetchSpots() {
        let fetchedSpots = dataManager.fetchSpots()
        print("📦 Fetched \(fetchedSpots.count) spots from database")
        state.spots = fetchedSpots
        state.refreshID = UUID()  // Force view refresh
        print("📦 Updated state.spots, count now: \(state.spots.count)")
        fetchedSpots.forEach { spot in
            print("  - \(spot.name)")
        }
    }

    /// Spots after applying the search text and the selected light filters.
    var filteredSpots: [Spot] {
        state.spots.filter { spot in
            let matchesSearch = state.searchText.isEmpty
                || spot.name.localizedCaseInsensitiveContains(state.searchText)
                || spot.address.formatted.localizedCaseInsensitiveContains(state.searchText)

            let matchesLight = state.selectedLightFilters.isEmpty
                || !state.selectedLightFilters.isDisjoint(with: spot.lightConditions)

            return matchesSearch && matchesLight
        }
    }

    func toggleFilter(_ light: LightType) {
        if state.selectedLightFilters.contains(light) {
            state.selectedLightFilters.remove(light)
        } else {
            state.selectedLightFilters.insert(light)
        }
    }
}

