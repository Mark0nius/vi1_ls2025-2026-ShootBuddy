//
//  RouteDetailViewState.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 16.06.2026.
//
import SwiftUI
import CoreLocation
import MapKit

@Observable
class RouteDetailViewState {
    var route: Route
    var refreshID: UUID = UUID()  // Used to force view refresh

    init(route: Route) {
        self.route = route
    }
    
    // MARK: - Computed Properties
    
    /// All coordinates from route stops
    var coordinates: [CLLocationCoordinate2D] {
        route.stops.map { $0.spot.coordinate }
    }
    
    /// Indexed stops with metadata for timeline display
    var indexedStops: [(index: Int, stop: RouteStop, isFirst: Bool, isLast: Bool)] {
        route.stops.enumerated().map { index, stop in
            (index, stop, index == 0, index == route.stops.count - 1)
        }
    }
}
