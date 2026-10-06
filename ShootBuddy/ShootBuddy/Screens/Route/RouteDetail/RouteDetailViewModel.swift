//
//  RouteDetailViewModel.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 16.06.2026.
//
import SwiftUI
import MapKit

@Observable
class RouteDetailViewModel {
    var state: RouteDetailViewState
    private var dataManager: DataManaging

    init(route: Route) {
        self.state = RouteDetailViewState(route: route)
        dataManager = DIContainer.shared.resolve()
    }
    
    func refreshRoute() {
        print("🔄 Refreshing route...")
        let allRoutes = dataManager.fetchRoutes()
        print("🔄 Fetched \(allRoutes.count) routes from database")
        
        guard let updatedRoute = allRoutes.first(where: { $0.id == state.route.id }) else {
            print("❌ Could not find updated route with ID \(state.route.id)")
            return
        }

        print("✅ Found updated route: \(updatedRoute.name)")
        state.route = updatedRoute
        state.refreshID = UUID()  // Force view refresh
        print("✅ State updated with new refreshID: \(state.refreshID)")
    }
    
    // MARK: - Map Position Calculation
    
    /// Calculates the optimal map camera position for displaying all route stops
    var mapCameraPosition: MapCameraPosition {
        let coordinates = state.coordinates
        
        guard !coordinates.isEmpty else {
            return .automatic
        }
        
        if coordinates.count == 1 {
            return .region(MKCoordinateRegion(
                center: coordinates[0],
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            ))
        }
        
        // Calculate bounding box for all coordinates
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5, // Add 50% padding
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        return .region(MKCoordinateRegion(center: center, span: span))
    }
    
    // MARK: - Formatting Utilities
    
    /// Formats a date as a short time string (e.g., "10:30 AM")
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Formats a time interval as a travel duration string (e.g., "2h 30m", "45 min")
    func formattedTravelTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "< 1 min"
        }
    }
}
