//
//  RouteGeneratorProtocol.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 17.06.2026.
//

import Foundation
import CoreLocation

/// Protocol for route generation service
protocol RouteGenerating {
    /// Generates an optimized route with spots scheduled in appropriate light windows
    /// - Parameters:
    ///   - selectedSpots: Spots the user explicitly wants to visit
    ///   - date: The date of the route
    ///   - startTime: When the route should start
    ///   - endTime: When the route should end
    ///   - desiredSpotCount: Total number of spots to include
    ///   - baseLocation: Starting location (used for calculating light windows)
    ///   - allAvailableSpots: All saved spots (for auto-filling)
    ///   - transportMode: How to travel between spots (driving or walking)
    /// - Returns: Scheduled route stops with assigned times
    func generateRoute(
        selectedSpots: [Spot],
        date: Date,
        startTime: Date,
        endTime: Date,
        desiredSpotCount: Int,
        baseLocation: CLLocationCoordinate2D,
        allAvailableSpots: [Spot],
        transportMode: TransportMode
    ) async -> [RouteStop]
}
