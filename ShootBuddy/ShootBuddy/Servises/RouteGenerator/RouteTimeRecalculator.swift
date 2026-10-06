//
//  RouteTimeRecalculator.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 17.06.2026.
//

import Foundation
import CoreLocation

/// Handles recalculation of route times with actual travel distances
struct RouteTimeRecalculator {
    private let lightCalculator: LightCalculating
    private let travelTimeCache: TravelTimeCache
    private let shootDuration: TimeInterval
    
    init(lightCalculator: LightCalculating, travelTimeCache: TravelTimeCache, shootDuration: TimeInterval) {
        self.lightCalculator = lightCalculator
        self.travelTimeCache = travelTimeCache
        self.shootDuration = shootDuration
    }
    
    /// Recalculates arrival and departure times based on actual travel time between spots
    /// while respecting light window constraints
    func recalculateTimesWithTravel(
        stops: [RouteStop],
        startTime: Date
    ) async -> [RouteStop] {
        guard !stops.isEmpty else { return stops }
        
        var recalculatedStops: [RouteStop] = []
        
        print("  🕐 Recalculating times with travel distances...")
        
        // Get light windows to validate assignments
        // Use the same day-at-noon fix to ensure correct calendar day
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: startTime)
        let dayAtNoon = calendar.date(from: dateComponents)?.addingTimeInterval(12 * 3600) ?? startTime
        
        let lightWindows = await lightCalculator.calculateLightWindows(for: dayAtNoon, at: stops.first!.spot.coordinate)
        
        // Sort stops by their CURRENT arrival time (preserve the optimized order!)
        // The optimizer already arranged them correctly based on time proximity
        let sortedStops = stops.sorted { $0.arrivalTime < $1.arrivalTime }
        
        for (index, stop) in sortedStops.enumerated() {
            // Find the light window for this stop's assigned light
            // Important: There can be multiple windows of the same type (e.g., 2 golden hours, 2 blue hours)
            // We need to find the window that contains the stop's arrival time, or the nearest one
            let candidateWindows = lightWindows.filter { $0.lightType == stop.assignedLight }
            
            guard !candidateWindows.isEmpty else {
                print("  ⚠️ Warning: No light window found for \(stop.assignedLight.name)")
                continue
            }
            
            // Find the window that contains the stop's arrival time, or the nearest one
            let assignedWindow: LightWindow
            if let matchingWindow = candidateWindows.first(where: { window in
                stop.arrivalTime >= window.start && stop.arrivalTime <= window.end
            }) {
                // Stop is already within a window of the correct type
                assignedWindow = matchingWindow
            } else {
                // Find the nearest window (by start time distance)
                assignedWindow = candidateWindows.min(by: { window1, window2 in
                    abs(window1.start.timeIntervalSince(stop.arrivalTime)) < abs(window2.start.timeIntervalSince(stop.arrivalTime))
                }) ?? candidateWindows[0]
            }
            
            // Calculate the earliest we can arrive at this stop and track travel time
            let travelTime: TimeInterval
            let earliestArrival: Date
            
            if index > 0 {
                // We need to travel from the previous stop
                let previousStop = recalculatedStops[index - 1]
                travelTime = await travelTimeCache.getTravelTime(
                    from: previousStop.spot.coordinate,
                    to: stop.spot.coordinate
                )
                
                let arrivalAfterTravel = previousStop.departureTime.addingTimeInterval(travelTime)
                
                print("  🚗 Travel from \(previousStop.spot.name) to \(stop.spot.name): \(Int(travelTime/60)) min")
                
                // Earliest arrival is either after travel or at the start of the light window
                earliestArrival = max(arrivalAfterTravel, assignedWindow.start)
                
                // Check if we can arrive in time for the light window
                if arrivalAfterTravel > assignedWindow.end {
                    print("  ⚠️ Warning: \(stop.spot.name) can't reach \(stop.assignedLight.name) window in time (arrives at \(formatTime(arrivalAfterTravel)), window ends at \(formatTime(assignedWindow.end)))")
                }
                
                if arrivalAfterTravel < assignedWindow.start {
                    print("  ⏰ Waiting for \(stop.assignedLight.name) window (from \(formatTime(arrivalAfterTravel)) to \(formatTime(assignedWindow.start)))")
                }
            } else {
                // First stop - no travel time
                travelTime = 0
                
                // Use the max of route start time or light window start
                earliestArrival = max(startTime, assignedWindow.start)
                
                if startTime < assignedWindow.start {
                    print("  ⏰ Starting route at \(formatTime(assignedWindow.start)) to match \(stop.assignedLight.name) window")
                }
            }
            
            // Make sure we don't exceed the light window
            let arrivalTime = earliestArrival
            let departureTime = arrivalTime.addingTimeInterval(shootDuration)
            
            // Validate that we fit within the window
            if departureTime > assignedWindow.end {
                print("  ⚠️ Warning: \(stop.spot.name) departs after \(stop.assignedLight.name) window ends (departs at \(formatTime(departureTime)), window ends at \(formatTime(assignedWindow.end)))")
            }
            
            // Create new stop with updated times including travel time
            let newStop = RouteStop(
                id: stop.id,
                spot: stop.spot,
                assignedLight: stop.assignedLight,
                arrivalTime: arrivalTime,
                departureTime: departureTime,
                note: stop.note,
                isAutoGenerated: stop.isAutoGenerated,
                travelTimeFromPrevious: travelTime
            )
            
            recalculatedStops.append(newStop)
            
            print("  📍 \(stop.spot.name): \(formatTime(newStop.arrivalTime)) - \(formatTime(newStop.departureTime)) (\(stop.assignedLight.name))")
        }
        
        return recalculatedStops
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
