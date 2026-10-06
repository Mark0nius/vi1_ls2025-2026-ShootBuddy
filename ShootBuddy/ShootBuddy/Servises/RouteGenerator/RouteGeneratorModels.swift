//
//  RouteGeneratorModels.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 17.06.2026.
//

import Foundation
import CoreLocation

// MARK: - Helper Types

/// A possible assignment of a spot to a specific light window
struct CandidateAssignment {
    let spot: Spot
    let lightWindow: LightWindow
    let priority: Int // Higher = more constrained = schedule first
}

/// Represents an occupied time range
struct TimeRange {
    let start: Date
    let end: Date
}

/// Represents a gap in the schedule where we could add more spots
struct Gap {
    let start: Date
    let end: Date
    let duration: TimeInterval
    let referenceLocation: CLLocationCoordinate2D?
}
