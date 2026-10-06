//
//  RouteGenerator.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 16.06.2026.
//  Refactored by Libor Jevický on 17.06.2026.
//

import Foundation
import CoreLocation
import MapKit

/// Service that generates optimized photography routes based on light conditions and travel time
final class RouteGenerator: RouteGenerating {
    private let lightCalculator: LightCalculating
    private let dataManager: DataManaging
    private let travelTimeCache = TravelTimeCache()
    
    // Configuration
    private let maxTravelTime: TimeInterval = 60 * 60 // 1 hour max between spots
    
    // Shoot duration (will be set from preset or use default)
    private var shootDuration: TimeInterval = 30 * 60 // Default 30 minutes
    
    init(lightCalculator: LightCalculating, dataManager: DataManaging) {
        self.lightCalculator = lightCalculator
        self.dataManager = dataManager
    }
    
    /// Generates an optimized route with spots scheduled in appropriate light windows
    func generateRoute(
        selectedSpots: [Spot],
        date: Date,
        startTime: Date,
        endTime: Date,
        desiredSpotCount: Int,
        baseLocation: CLLocationCoordinate2D,
        allAvailableSpots: [Spot],
        transportMode: TransportMode
    ) async -> [RouteStop] {
        
        print("🚀 Generating route with \(selectedSpots.count) selected spots, target: \(desiredSpotCount)")
        
        // Debug: Print available spots and their light conditions
        if !allAvailableSpots.isEmpty {
            print("")
            print("🔍 DEBUG: Available spots and their light conditions:")
            for spot in allAvailableSpots {
                let lights = spot.lightConditions.isEmpty ? "⚠️ NONE - SPOT HAS NO LIGHT CONDITIONS!" : spot.lightConditions.map { $0.name }.joined(separator: ", ")
                print("   📍 \(spot.name): [\(lights)]")
            }
            print("")
        }
        
        // Clear cache for new route and set transport mode
        await travelTimeCache.clear()
        await travelTimeCache.setTransportMode(transportMode.mkDirectionsType)
        
        print("🚗 Using transport mode: \(transportMode.rawValue)")
        
        // Load current shoot preset to determine spot duration
        let presets = dataManager.fetchPresets()
        if let currentPreset = presets.first {
            shootDuration = currentPreset.slotDuration
            print("⏱️ Using preset '\(currentPreset.name)': \(currentPreset.totalMinutes) minutes per spot")
        } else {
            shootDuration = 30 * 60 // Fallback to 30 minutes
            print("⏱️ No preset found, using default: 30 minutes per spot")
        }
        
        // Step 1: Calculate light windows for the day
        // Extract the calendar date to ensure we get the right day regardless of timezone
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: startTime)
        let dayAtNoon = calendar.date(from: dateComponents)?.addingTimeInterval(12 * 3600) ?? startTime
        
        let lightWindows = await lightCalculator.calculateLightWindows(for: dayAtNoon, at: baseLocation)
        print("💡 Found \(lightWindows.count) light windows for the day")
        for window in lightWindows {
            print("   ☀️ \(window.lightType.name): \(formatTime(window.start)) - \(formatTime(window.end))")
        }
        
        // Step 2: Create candidate assignments (spot + matching light window)
        // If no spots are explicitly selected, use all available spots for candidates
        let spotsToConsider = selectedSpots.isEmpty ? allAvailableSpots : selectedSpots
        
        let candidates = createCandidateAssignments(
            spots: spotsToConsider,
            lightWindows: lightWindows,
            routeStart: startTime,
            routeEnd: endTime
        )
        
        print("📋 Created \(candidates.count) candidate assignments from \(spotsToConsider.count) spots")
        
        // Step 3: Schedule spots using constraint-based algorithm
        let scheduler = RouteScheduler(travelTimeCache: travelTimeCache, shootDuration: shootDuration)
        var scheduledStops = await scheduler.scheduleSpots(
            candidates: candidates,
            startTime: startTime,
            endTime: endTime,
            maxTravelTime: maxTravelTime,
            targetSpotCount: desiredSpotCount
        )
        
        print("✅ Scheduled \(scheduledStops.count) spots")
        
        // Step 4: Fill gaps with nearby spots
        if scheduledStops.count < desiredSpotCount {
            let gapFiller = RouteGapFiller(travelTimeCache: travelTimeCache, shootDuration: shootDuration)
            scheduledStops = await gapFiller.fillGapsWithNearbySpots(
                currentStops: scheduledStops,
                lightWindows: lightWindows,
                availableSpots: allAvailableSpots,
                targetCount: desiredSpotCount,
                startTime: startTime,
                endTime: endTime,
                baseLocation: baseLocation
            )
        }
        
        // Step 5: Optimize route order within light windows (minimize travel)
        let optimizer = RouteOptimizer()
        scheduledStops = await optimizer.optimizeRouteOrder(stops: scheduledStops)
        
        // Step 6: Recalculate times with actual travel
        let timeRecalculator = RouteTimeRecalculator(
            lightCalculator: lightCalculator,
            travelTimeCache: travelTimeCache,
            shootDuration: shootDuration
        )
        scheduledStops = await timeRecalculator.recalculateTimesWithTravel(
            stops: scheduledStops,
            startTime: startTime
        )
        
        // Step 7: Sort by time and return
        return scheduledStops.sorted { $0.arrivalTime < $1.arrivalTime }
    }
    
    // MARK: - Private Helpers
    
    /// Creates all possible spot-light window combinations
    private func createCandidateAssignments(
        spots: [Spot],
        lightWindows: [LightWindow],
        routeStart: Date,
        routeEnd: Date
    ) -> [CandidateAssignment] {
        var candidates: [CandidateAssignment] = []
        
        print("  📅 Route window: \(formatDateTime(routeStart)) - \(formatDateTime(routeEnd))")
        print("  📅 Light windows calculated for: \(formatDateTime(lightWindows.first?.start ?? routeStart))")
        
        
        for spot in spots {
            // Find windows that match this spot's light preferences
            // Windows must overlap with route time (not necessarily entirely within it)
            let matchingWindows = lightWindows.filter { window in
                let matchesLight = spot.lightConditions.contains(window.lightType)
                let overlapsRoute = window.end > routeStart && window.start < routeEnd
                
                // Debug: Show why windows are rejected
                if matchesLight && !overlapsRoute {
                    print("    ⚠️ '\(spot.name)' wants \(window.lightType.name) (\(formatDateTime(window.start))-\(formatDateTime(window.end))), but it doesn't overlap route (\(formatDateTime(routeStart))-\(formatDateTime(routeEnd)))")
                }
                
                return matchesLight && overlapsRoute
            }
            
            print("  🔎 Spot '\(spot.name)' matches \(matchingWindows.count) windows: \(matchingWindows.map { $0.lightType.name }.joined(separator: ", "))")
            
            // Create a candidate for each matching window
            for window in matchingWindows {
                candidates.append(CandidateAssignment(
                    spot: spot,
                    lightWindow: window,
                    priority: calculatePriority(spot: spot, matchCount: matchingWindows.count)
                ))
            }
        }
        
        // Sort by priority (spots with fewer options go first)
        return candidates.sorted { $0.priority > $1.priority }
    }
    
    /// Calculate priority: spots with fewer light options should be scheduled first
    private func calculatePriority(spot: Spot, matchCount: Int) -> Int {
        // Inverse of match count = higher priority for constrained spots
        return max(1, 100 - matchCount * 10)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


