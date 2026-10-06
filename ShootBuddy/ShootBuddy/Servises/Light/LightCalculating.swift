//
//  LightCalculating.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 16.06.2026.
//

import Foundation
import CoreLocation

protocol LightCalculating {
    /// Calculates all light windows for a given date and location
    /// - Parameters:
    ///   - date: The date to calculate light windows for
    ///   - coordinate: The geographic coordinate (lat/lon)
    /// - Returns: Array of LightWindow objects representing available light conditions
    func calculateLightWindows(for date: Date, at coordinate: CLLocationCoordinate2D) async -> [LightWindow]
    
    /// Finds the next occurrence of a specific light type starting from a given time
    /// - Parameters:
    ///   - lightType: The type of light to find
    ///   - startTime: When to start searching
    ///   - coordinate: Location coordinates
    /// - Returns: The next available light window, if any
    func nextWindow(for lightType: LightType, after startTime: Date, at coordinate: CLLocationCoordinate2D) async -> LightWindow?
}
