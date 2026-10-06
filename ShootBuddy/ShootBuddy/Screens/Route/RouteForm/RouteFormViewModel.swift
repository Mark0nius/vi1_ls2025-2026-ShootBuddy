//
//  RouteFormViewModel.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 15.06.2026.
//

import SwiftUI
import CoreLocation

/// Result of trying to add a spot to the route draft.
enum SpotAdditionResult {
    case added
    case duplicate
    case limitReached(LimitExceededInfo)
}

/// Information about why a spot cannot be added (shown in the replacement dialog).
struct LimitExceededInfo {
    let candidateSpot: Spot
    let limitType: LimitType
    
    enum LimitType {
        case totalSpots
        case lightCondition(LightType)
        
        var message: String {
            switch self {
            case .totalSpots:
                return "You have selected the maximum number of spots."
            case .lightCondition(let light):
                return "You have selected maximum number of \(light.name) photoshoots."
            }
        }
    }
}

// Stores editable route values and prepares the final Route model for saving.
@Observable
final class RouteFormViewModel {
    var state: RouteFormViewState
    
    private var editedRoute: Route?
    private var dataManager: DataManaging
    private var routeGenerator: RouteGenerating

    init(
        route: Route? = nil,
        dataManager: DataManaging = DIContainer.shared.resolve(),
        routeGenerator: RouteGenerating = DIContainer.shared.resolve()
    ) {
        self.editedRoute = route
        self.dataManager = dataManager
        self.routeGenerator = routeGenerator
        
        if let route {
            self.state = RouteFormViewState(route: route)
        } else {
            self.state = RouteFormViewState()
        }
    }

    // Tells the view whether it should show Add or Edit copy.
    var isEditing: Bool {
        editedRoute != nil
    }

    // Title shown in the form header.
    var title: String {
        isEditing ? "Edit Route" : "New Route"
    }

    // Save is enabled only when required values are present and valid.
    var canSave: Bool {
        !trimmed(state.name).isEmpty
            && (parsedSpotCount != nil || !state.selectedSpots.isEmpty)
            && state.startDate < state.endDate
            && !state.isSaving
    }

    // Loads saved spots for the "Add spot..." picker.
    func fetchAvailableSpots() {
        state.availableSpots = dataManager.fetchSpots()
        print("🔍 Fetched \(state.availableSpots.count) spots")
        state.availableSpots.forEach { spot in
            print("  - \(spot.name)")
        }
        
        // IMPORTANT: When editing, refresh selected spots with current data from database
        // This ensures we have the latest light conditions and other spot properties
        if isEditing {
            refreshSelectedSpots()
        }
    }
    
    /// Refreshes selected spots with current data from database
    /// This is crucial when editing a route, as spots may have been updated
    /// since the route was created (e.g., light conditions changed)
    private func refreshSelectedSpots() {
        print("🔄 Refreshing selected spots with current database data")
        
        var refreshedSpots: [Spot] = []
        
        for oldSpot in state.selectedSpots {
            // Find the current version of this spot in the database
            if let currentSpot = state.availableSpots.first(where: { $0.id == oldSpot.id }) {
                print("  ✅ Refreshed: \(currentSpot.name) - lights: \(currentSpot.lightConditions.map { $0.name }.joined(separator: ", "))")
                refreshedSpots.append(currentSpot)
            } else {
                // Spot was deleted from database, keep the old version
                print("  ⚠️ Spot not found in database, keeping old data: \(oldSpot.name)")
                refreshedSpots.append(oldSpot)
            }
        }
        
        state.selectedSpots = refreshedSpots
        print("✅ Selected spots refreshed")
    }

    /// Attempts to add a spot to the route, validating against limits.
    /// Returns a result indicating whether the spot was added or why it can't be.
    func attemptToAddSpot(_ spot: Spot) -> SpotAdditionResult {
        print("🎯 Attempting to add spot: \(spot.name)")
        
        // Check for duplicates
        if state.selectedSpots.contains(where: { $0.id == spot.id }) {
            print("  ❌ Duplicate")
            return .duplicate
        }
        
        // If no limit specified, just add the spot
        guard let limit = parsedSpotCount else {
            print("  ✅ No limit, adding spot")
            state.selectedSpots.append(spot)
            print("  📊 Selected spots count: \(state.selectedSpots.count)")
            return .added
        }
        
        // Check total spot limit
        if state.selectedSpots.count >= limit {
            print("  ❌ Total limit reached")
            return .limitReached(LimitExceededInfo(
                candidateSpot: spot,
                limitType: .totalSpots
            ))
        }
        
        // Check light condition limits
        // For each light type in the new spot, verify we haven't exceeded daily limits
        for lightType in spot.lightConditions {
            let currentCountForLight = state.selectedSpots.filter { selectedSpot in
                selectedSpot.lightConditions.contains(lightType)
            }.count
            
            if currentCountForLight >= lightType.dailyWindowCount {
                print("  ❌ Light condition limit reached for \(lightType.name)")
                return .limitReached(LimitExceededInfo(
                    candidateSpot: spot,
                    limitType: .lightCondition(lightType)
                ))
            }
        }
        
        // All validations passed, add the spot
        print("  ✅ All validations passed, adding spot")
        state.selectedSpots.append(spot)
        print("  📊 Selected spots count: \(state.selectedSpots.count)")
        return .added
    }

    // Replaces an existing spot with a candidate spot.
    func replaceSpot(_ existingSpot: Spot, with candidateSpot: Spot) {
        guard let index = state.selectedSpots.firstIndex(where: { $0.id == existingSpot.id }) else {
            return
        }
        state.selectedSpots[index] = candidateSpot
    }
    
    /// Increases the desired spot count and adds the spot
    /// Used when user chooses to expand the route instead of replacing a spot
    func increaseSpotCountAndAdd(_ spot: Spot) {
        // Increase the desired spot count
        let currentCount = parsedSpotCount ?? state.selectedSpots.count
        state.desiredSpotCount = String(currentCount + 1)
        
        // Add the spot
        state.selectedSpots.append(spot)
        
        print("✅ Increased desired spot count to \(currentCount + 1) and added \(spot.name)")
    }

    /// Initiates spot removal - shows confirmation dialog if editing
    func initiateRemoveSpot(_ spot: Spot) {
        if isEditing {
            // Show confirmation dialog
            state.spotToRemove = spot
        } else {
            // Creating new route - remove immediately
            removeSpot(spot)
        }
    }
    
    /// Removes a spot and decreases the desired count
    func removeSpotAndDecrease(_ spot: Spot) {
        // Decrease the desired spot count
        if let currentCount = parsedSpotCount, currentCount > 1 {
            state.desiredSpotCount = String(currentCount - 1)
            print("✅ Decreased desired spot count to \(currentCount - 1)")
        }
        
        // Remove the spot
        removeSpot(spot)
    }

    /// Removes a selected spot from the route draft without changing count
    func removeSpot(_ spot: Spot) {
        state.selectedSpots.removeAll { $0.id == spot.id }
        print("🗑️ Removed spot: \(spot.name)")
    }

    // Saves the route and returns success status
    func saveRoute() async -> Bool {
        guard canSave else {
            print("Missing required fields")
            return false
        }
        
        state.isSaving = true
        state.errorMessage = nil
        
        guard let route = await makeRoute() else {
            state.isSaving = false
            state.errorMessage = "Could not create route."
            return false
        }
        
        dataManager.saveRoute(route)
        editedRoute = route
        
        state.isSaving = false
        return true
    }
    
    // Deletes the route being edited
    func deleteRoute() -> Bool {
        guard let editedRoute else {
            return false
        }
        
        dataManager.deleteRoute(editedRoute)
        return true
    }

    // Creates the Route model that can be saved into Core Data.
    private func makeRoute() async -> Route? {
        // Use parsed spot count if available, otherwise use number of selected spots
        let desiredSpotCount = parsedSpotCount ?? state.selectedSpots.count
        
        // Must have at least some spots
        guard desiredSpotCount > 0 else {
            return nil
        }

        // Generate optimized route stops using the route generator
        let optimizedStops = await generateOptimizedStops(desiredSpotCount: desiredSpotCount)

        return Route(
            id: editedRoute?.id ?? UUID(),
            name: trimmed(state.name),
            desiredSpotCount: desiredSpotCount,
            startDate: state.startDate,
            endDate: state.endDate,
            stops: optimizedStops,
            note: trimmed(state.note).isEmpty ? nil : trimmed(state.note),
            transportMode: SettingsViewModel.currentTransportMode,
            calendarEventID: editedRoute?.calendarEventID
        )
    }
    
    // Generates optimized route stops using light windows and travel time
    private func generateOptimizedStops(desiredSpotCount: Int) async -> [RouteStop] {
        print("🎬 generateOptimizedStops called with desiredSpotCount: \(desiredSpotCount)")
        print("📊 Selected spots count: \(state.selectedSpots.count)")
        print("📊 Available spots count: \(state.availableSpots.count)")
        
        // Determine base location for light calculations
        let baseLocation: CLLocationCoordinate2D
        
        if let firstSpot = state.selectedSpots.first {
            // Use first selected spot's location
            baseLocation = firstSpot.coordinate
            print("🗺️ Using first selected spot location: \(firstSpot.name)")
        } else if let firstAvailable = state.availableSpots.first {
            // No selected spots - use first available spot
            baseLocation = firstAvailable.coordinate
            print("🗺️ Using first available spot location: \(firstAvailable.name)")
        } else {
            // No spots at all - can't generate route
            print("⚠️ No spots available to generate route")
            return []
        }
        
        print("🚀 Calling routeGenerator.generateRoute...")
        let optimizedStops = await routeGenerator.generateRoute(
            selectedSpots: state.selectedSpots, // Can be empty!
            date: state.startDate,
            startTime: state.startDate,
            endTime: state.endDate,
            desiredSpotCount: desiredSpotCount,
            baseLocation: baseLocation,
            allAvailableSpots: state.availableSpots,
            transportMode: SettingsViewModel.currentTransportMode
        )
        
        print("✅ RouteGenerator returned \(optimizedStops.count) stops")
        
        // If generation failed or returned empty, fallback to simple stops (only if we have selected spots)
        if optimizedStops.isEmpty && !state.selectedSpots.isEmpty {
            print("⚠️ Generation returned empty but we have selected spots, using fallback")
            return makeStops()
        }
        
        return optimizedStops
    }

    private var parsedSpotCount: Int? {
        guard let count = Int(state.desiredSpotCount), count > 0 else {
            return nil
        }
        return count
    }

    // Converts selected spots into simple route stops.
    // Later this can be replaced by the real route generator.
    private func makeStops() -> [RouteStop] {
        state.selectedSpots.map { spot in
            RouteStop(
                spot: spot,
                assignedLight: spot.lightConditions.first ?? .noonLight,
                arrivalTime: state.startDate,
                departureTime: state.endDate,
                note: spot.note
            )
        }
    }
    
    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


