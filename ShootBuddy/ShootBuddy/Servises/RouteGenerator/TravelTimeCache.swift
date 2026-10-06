//
//  TravelTimeCache.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 17.06.2026.
//

import Foundation
import CoreLocation
import MapKit

/// Cache for travel time calculations to avoid redundant API calls
actor TravelTimeCache {
    private var cache: [String: TimeInterval] = [:]
    private var currentTransportMode: MKDirectionsTransportType = .automobile
    
    func clear() {
        cache.removeAll()
    }
    
    func setTransportMode(_ mode: MKDirectionsTransportType) {
        if mode != currentTransportMode {
            currentTransportMode = mode
            cache.removeAll()  // Clear cache when mode changes
        }
    }
    
    func getTravelTime(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async -> TimeInterval {
        let key = cacheKey(from: from, to: to)
        
        // Return cached value if available
        if let cached = cache[key] {
            return cached
        }
        
        // Calculate new travel time
        let travelTime = await calculateTravelTime(from: from, to: to)
        
        // Store in cache
        cache[key] = travelTime
        
        return travelTime
    }
    
    private func cacheKey(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> String {
        // Round coordinates to 4 decimal places for cache key
        let fromLat = String(format: "%.4f", from.latitude)
        let fromLon = String(format: "%.4f", from.longitude)
        let toLat = String(format: "%.4f", to.latitude)
        let toLon = String(format: "%.4f", to.longitude)
        return "\(fromLat),\(fromLon)-\(toLat),\(toLon)"
    }
    
    private func calculateTravelTime(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async -> TimeInterval {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = currentTransportMode  // Use the current transport mode
        
        let directions = MKDirections(request: request)
        
        do {
            let response = try await directions.calculate()
            return response.routes.first?.expectedTravelTime ?? 10 * 60 // Default 10 min
        } catch {
            print("⚠️ Could not calculate travel time: \(error)")
            // Fallback: estimate based on straight-line distance
            let distance = MKMapPoint(from).distance(to: MKMapPoint(to))
            
            // Adjust speed based on transport mode
            let metersPerSecond: Double = currentTransportMode == .walking ? 1.4 : 15 // ~5 km/h walking, ~54 km/h driving
            return distance / metersPerSecond
        }
    }
}
