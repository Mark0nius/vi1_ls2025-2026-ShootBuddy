//
//  RouteOptimizer.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 17.06.2026.
//

import Foundation
import MapKit

/// Handles route optimization to minimize travel distance
struct RouteOptimizer {
    
    /// Optimizes the route order within each light window to minimize travel time
    /// Groups stops by light window and reorders them geographically
    func optimizeRouteOrder(stops: [RouteStop]) async -> [RouteStop] {
        guard stops.count > 2 else { return stops }
        
        print("  🔄 Optimizing route order to minimize travel distance...")
        
        // Group stops by their assigned light window (using arrival time to determine which window)
        var lightWindowGroups: [[RouteStop]] = []
        var currentGroup: [RouteStop] = []
        var lastLightType: LightType? = nil
        
        // Sort by arrival time first
        let sortedStops = stops.sorted { $0.arrivalTime < $1.arrivalTime }
        
        for stop in sortedStops {
            // If light type changes or there's a big time gap, start a new group
            if let last = lastLightType, 
               let lastStop = currentGroup.last,
               (last != stop.assignedLight || stop.arrivalTime.timeIntervalSince(lastStop.departureTime) > 3600) {
                // Save current group and start new one
                if !currentGroup.isEmpty {
                    lightWindowGroups.append(currentGroup)
                }
                currentGroup = [stop]
            } else {
                currentGroup.append(stop)
            }
            lastLightType = stop.assignedLight
        }
        
        // Don't forget the last group
        if !currentGroup.isEmpty {
            lightWindowGroups.append(currentGroup)
        }
        
        print("  📊 Found \(lightWindowGroups.count) light window groups to optimize")
        
        // Optimize each group using nearest-neighbor algorithm
        var optimizedStops: [RouteStop] = []
        
        for (groupIndex, group) in lightWindowGroups.enumerated() {
            guard group.count > 1 else {
                optimizedStops.append(contentsOf: group)
                continue
            }
            
            print("  🗺️  Optimizing group \(groupIndex + 1) with \(group.count) stops (\(group.first!.assignedLight.name))")
            
            // Nearest neighbor algorithm: start with first stop, always go to nearest unvisited
            var unvisited = group
            var optimizedGroup: [RouteStop] = []
            
            // Start with the stop that comes first chronologically
            if let firstStop = unvisited.first {
                optimizedGroup.append(firstStop)
                unvisited.removeAll { $0.id == firstStop.id }
                
                // Build route by always choosing nearest unvisited stop
                while !unvisited.isEmpty {
                    let currentLocation = optimizedGroup.last!.spot.coordinate
                    
                    // Find nearest unvisited stop
                    var nearestStop: RouteStop?
                    var shortestDistance = Double.infinity
                    
                    for stop in unvisited {
                        let distance = MKMapPoint(currentLocation).distance(to: MKMapPoint(stop.spot.coordinate))
                        if distance < shortestDistance {
                            shortestDistance = distance
                            nearestStop = stop
                        }
                    }
                    
                    if let nearest = nearestStop {
                        optimizedGroup.append(nearest)
                        unvisited.removeAll { $0.id == nearest.id }
                        print("    ↪️  \(nearest.spot.name) (\(String(format: "%.1fkm", shortestDistance / 1000)))")
                    }
                }
            }
            
            optimizedStops.append(contentsOf: optimizedGroup)
        }
        
        return optimizedStops
    }
}
