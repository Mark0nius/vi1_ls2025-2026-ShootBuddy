//
//  DataManaging.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 13.06.2026.
//
import Foundation

protocol DataManaging {
    // Spots
    func saveSpot(_ spot: Spot)
    func fetchSpots() -> [Spot]
    func deleteSpot(_ spot: Spot)

    // Routes
    func saveRoute(_ route: Route)
    func fetchRoutes() -> [Route]
    func deleteRoute(_ route: Route)

    // Shoot presets
    func savePreset(_ preset: ShootPreset)
    func fetchPresets() -> [ShootPreset]
    func deletePreset(_ preset: ShootPreset)
}

