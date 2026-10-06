//
//  RouteFormViewState.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 16.06.2026.
//

import SwiftUI

@Observable
class RouteFormViewState {
    var name: String = ""
    var desiredSpotCount: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date().addingTimeInterval(60 * 60)
    var selectedSpots: [Spot] = []
    var note: String = ""
    
    // Available spots for picker
    var availableSpots: [Spot] = []
    
    // View-specific presentation state
    var isSpotPickerPresented: Bool = false
    var limitExceededInfo: LimitExceededInfo? = nil
    var spotToRemove: Spot? = nil  // NEW: Track spot pending removal
    
    var isSaving: Bool = false
    var errorMessage: String? = nil
    
    init() {}
    
    init(route: Route) {
        name = route.name
        desiredSpotCount = String(route.desiredSpotCount)
        startDate = route.startDate
        endDate = route.endDate
        selectedSpots = route.stops.map(\.spot)
        note = route.note ?? ""
    }
}
