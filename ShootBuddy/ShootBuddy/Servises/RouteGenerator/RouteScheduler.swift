//
//  RouteScheduler.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 17.06.2026.
//

import Foundation
import CoreLocation

/// Handles the core scheduling logic for route stops
struct RouteScheduler {
    private let travelTimeCache: TravelTimeCache
    private let shootDuration: TimeInterval
    private let timeSlotIncrement: TimeInterval = 15 * 60 // Try slots every 15 minutes
    
    init(travelTimeCache: TravelTimeCache, shootDuration: TimeInterval) {
        self.travelTimeCache = travelTimeCache
        self.shootDuration = shootDuration
    }
    
    /// Schedules spots into time slots, respecting constraints
    /// Uses a smart algorithm that considers:
    /// 1. Window utilization (prefers filling current window before moving to next)
    /// 2. Shared light conditions (groups spots with same light together)
    /// 3. Geographic proximity (minimizes travel distance)
    /// 4. Time continuity (minimizes waiting between stops)
    func scheduleSpots(
        candidates: [CandidateAssignment],
        startTime: Date,
        endTime: Date,
        maxTravelTime: TimeInterval,
        targetSpotCount: Int
    ) async -> [RouteStop] {
        var scheduledStops: [RouteStop] = []
        var usedSpotIDs: Set<UUID> = []
        var currentTime = startTime
        var currentWindow: LightWindow? = nil
        
        print("  🎯 Target spot count: \(targetSpotCount)")
        
        // Group candidates by spot for easier lookup
        var candidatesBySpot: [UUID: [CandidateAssignment]] = [:]
        for candidate in candidates {
            candidatesBySpot[candidate.spot.id, default: []].append(candidate)
        }
        
        // Continue scheduling until we reach target count or run out of spots or time
        while scheduledStops.count < targetSpotCount && usedSpotIDs.count < candidatesBySpot.count {
            var bestCandidate: CandidateAssignment?
            var bestScore: Double = -.infinity
            var bestArrival: Date?
            var bestWaitTime: TimeInterval = .infinity
            
            // Evaluate all remaining candidates
            for (spotID, spotCandidates) in candidatesBySpot {
                // Skip already scheduled spots
                if usedSpotIDs.contains(spotID) {
                    continue
                }
                
                // Try each light window option for this spot
                for candidate in spotCandidates {
                    // Calculate travel time from last stop
                    let travelTime: TimeInterval
                    if let lastStop = scheduledStops.last {
                        travelTime = await travelTimeCache.getTravelTime(
                            from: lastStop.spot.coordinate,
                            to: candidate.spot.coordinate
                        )
                        
                        // Skip if travel is too long
                        if travelTime > maxTravelTime {
                            continue
                        }
                    } else {
                        travelTime = 0
                    }
                    
                    // Calculate when we could arrive
                    let earliestArrival = currentTime.addingTimeInterval(travelTime)
                    
                    // Must arrive within the light window
                    guard earliestArrival <= candidate.lightWindow.end else {
                        continue // Can't make it to this window in time
                    }
                    
                    let arrivalTime = max(earliestArrival, candidate.lightWindow.start)
                    let departureTime = arrivalTime.addingTimeInterval(shootDuration)
                    
                    // Must finish within window and route end time
                    guard departureTime <= candidate.lightWindow.end,
                          departureTime <= endTime else {
                        continue
                    }
                    
                    // Calculate wait time (if we have to wait for the window to start)
                    let waitTime = max(0, candidate.lightWindow.start.timeIntervalSince(earliestArrival))
                    
                    // Calculate score (higher = better)
                    // Factors:
                    // 1. Window continuity bonus (prefer staying in same window)
                    // 2. Shared light bonus (prefer spots that share light with unscheduled spots)
                    // 3. Minimize wait time (important - avoid gaps in schedule)
                    // 4. Minimize travel distance (important for geographic efficiency)
                    // 5. Prefer spots with fewer light options (minor tiebreaker)
                    
                    let waitScore = -waitTime / 60.0 // Negative minutes of waiting  
                    let travelScore = -travelTime / 60.0 // Negative minutes of travel
                    let priorityScore = Double(candidate.priority) / 100.0 // 0-1 range
                    
                    // Window continuity bonus
                    var windowContinuityBonus: Double = 0
                    if let current = currentWindow {
                        // Check if this candidate is for the same window instance
                        let sameWindow = (candidate.lightWindow.lightType == current.lightType &&
                                        abs(candidate.lightWindow.start.timeIntervalSince(current.start)) < 60)
                        
                        if sameWindow {
                            // Big bonus for staying in the same window
                            windowContinuityBonus = 600.0
                        }
                    }
                    
                    // NEW: Shared light bonus
                    // Count how many OTHER unscheduled spots want this same light type
                    var sharedLightBonus: Double = 0
                    let unscheduledSpots = candidatesBySpot.keys.filter { !usedSpotIDs.contains($0) && $0 != spotID }
                    var spotsWithSameLight = 0
                    
                    for otherSpotID in unscheduledSpots {
                        if let otherCandidates = candidatesBySpot[otherSpotID] {
                            if otherCandidates.contains(where: { $0.lightWindow.lightType == candidate.lightWindow.lightType }) {
                                spotsWithSameLight += 1
                            }
                        }
                    }
                    
                    // Give bonus based on how many spots share this light
                    // This encourages grouping spots with the same light together
                    // Use a large multiplier to overcome wait time penalties
                    sharedLightBonus = Double(spotsWithSameLight) * 300.0
                    
                    // Weighted score
                    let score = windowContinuityBonus + sharedLightBonus + (waitScore * 1.0) + (travelScore * 2.0) + (priorityScore * 0.1)
                    
                    // Debug: Print scoring details
                    if windowContinuityBonus > 0 || sharedLightBonus > 0 {
                        var bonusText = ""
                        if windowContinuityBonus > 0 { bonusText += "SAME_WINDOW_BONUS " }
                        if sharedLightBonus > 0 { bonusText += "SHARED_LIGHT_BONUS(\(spotsWithSameLight)spots) " }
                        print("      🔢 Evaluating \(candidate.spot.name) for \(candidate.lightWindow.lightType.name): wait=\(Int(waitTime/60))m, travel=\(Int(travelTime/60))m, priority=\(candidate.priority), \(bonusText)→ score=\(String(format: "%.2f", score))")
                    } else {
                        print("      🔢 Evaluating \(candidate.spot.name) for \(candidate.lightWindow.lightType.name): wait=\(Int(waitTime/60))m, travel=\(Int(travelTime/60))m, priority=\(candidate.priority) → score=\(String(format: "%.2f", score))")
                    }
                    
                    // Choose the best option
                    if score > bestScore {
                        bestScore = score
                        bestCandidate = candidate
                        bestArrival = arrivalTime
                        bestWaitTime = waitTime
                    }
                }
            }
            
            // If we found a valid candidate, schedule it
            guard let candidate = bestCandidate,
                  let arrivalTime = bestArrival else {
                // No more valid candidates
                print("  ⚠️ No more valid candidates found (scheduled \(scheduledStops.count)/\(targetSpotCount))")
                break
            }
            
            let departureTime = arrivalTime.addingTimeInterval(shootDuration)
            
            let stop = RouteStop(
                spot: candidate.spot,
                assignedLight: candidate.lightWindow.lightType,
                arrivalTime: arrivalTime,
                departureTime: departureTime,
                note: candidate.spot.note,
                isAutoGenerated: false
            )
            
            scheduledStops.append(stop)
            usedSpotIDs.insert(candidate.spot.id)
            currentTime = departureTime
            currentWindow = candidate.lightWindow // Track current window
            
            if bestWaitTime > 0 {
                print("  📍 Scheduled: \(candidate.spot.name) at \(formatTime(arrivalTime)) (\(candidate.lightWindow.lightType.name)) [wait: \(Int(bestWaitTime/60))m] [\(scheduledStops.count)/\(targetSpotCount)]")
            } else {
                print("  📍 Scheduled: \(candidate.spot.name) at \(formatTime(arrivalTime)) (\(candidate.lightWindow.lightType.name)) [\(scheduledStops.count)/\(targetSpotCount)]")
            }
            
            // Check if we've reached the target
            if scheduledStops.count >= targetSpotCount {
                print("  ✅ Target spot count reached (\(targetSpotCount))")
                break
            }
        }
        
        return scheduledStops
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
