//
//  SpotDetailViewModel.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 15.06.2026.
//
import SwiftUI
import CoreLocation

@Observable
class SpotDetailViewModel {
    var state: SpotDetailViewState
    private var apiManager: APIManaging
    private var dataManager: DataManaging

    init(spot: Spot) {
        self.state = SpotDetailViewState(spot: spot)
        apiManager = DIContainer.shared.resolve()
        dataManager = DIContainer.shared.resolve()
    }

    func fetchWeatherData() {
        Task { @MainActor in
            do {
                // Requests `current=weather_code` for the spot's location.
                // Add this case to your WeatherDataRouter (same shape as the
                // CityGuide `dailyMaxTemperature` endpoint, but current weather).
                let endpoint = WeatherDataRouter.weather(
                    long: state.spot.coordinate.longitude,
                    lat: state.spot.coordinate.latitude
                )

                let weatherData: WeatherData = try await apiManager.request(endpoint)
                state.weather = weatherData.current.condition
            } catch {
                print("❌ \(error)")
            }
        }
    }
    
    func refreshSpot() {
        print("🔄 Refreshing spot...")
        let allSpots = dataManager.fetchSpots()
        print("🔄 Fetched \(allSpots.count) spots from database")
        
        guard let updatedSpot = allSpots.first(where: { $0.id == state.spot.id }) else {
            print("❌ Could not find updated spot with ID \(state.spot.id)")
            return
        }

        print("✅ Found updated spot: \(updatedSpot.name)")
        state.spot = updatedSpot
        state.refreshID = UUID()  // Force view refresh
        print("✅ State updated with new refreshID: \(state.refreshID)")
        fetchWeatherData()
    }
}
