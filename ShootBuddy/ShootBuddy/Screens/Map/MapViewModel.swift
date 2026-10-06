//
//  MapViewModel.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//
import SwiftUI
import MapKit
import CoreLocation

@Observable
class MapViewModel {
    var state: MapViewState = MapViewState()

    private var dataManager: DataManaging
    private var locationManager: LocationManaging

    init() {
        dataManager = DIContainer.shared.resolve()
        locationManager = DIContainer.shared.resolve()
    }

    func fetchSpots() {
        state.spots = dataManager.fetchSpots()
    }

    func moveCameraToUserLocation() {
        guard let currentLocation = locationManager.getCurrentLocation() else {
            return
        }

        state.cameraPosition = .camera(
            .init(
                centerCoordinate: currentLocation,
                distance: 6000
            )
        )
    }

    func changeMapStyle(_ mapStyle: ShootBuddyMapStyle) {
        state.selectedMapStyle = mapStyle
    }

    func selectSpot(_ spot: Spot) {
        state.selectedSpot = spot
    }

    func clearSelectedSpot() {
        state.selectedSpot = nil
    }

    // Stores the latest finger position so a long press can be converted to map coordinates.
    func updateLongPressLocation(_ location: CGPoint) {
        state.longPressLocation = location
    }

    // Opens the new spot sheet with the coordinate selected by long press.
    func startNewSpot(at coordinate: CLLocationCoordinate2D) {
        state.newSpotDraft = MapSpotDraft(coordinate: coordinate)
    }

    // Clears the temporary new spot state after saving or closing the sheet.
    func clearNewSpotDraft() {
        state.newSpotDraft = nil
        state.longPressLocation = nil
    }
}
