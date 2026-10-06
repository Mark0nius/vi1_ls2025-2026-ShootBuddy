//
//  SpotAddViewState.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//
import SwiftUI
import MapKit

@Observable
class SpotAddViewState {
    var coordinates: CLLocationCoordinate2D = .init(
        latitude: 49.2068018498442,
        longitude: 16.608120972760936
    )

    var name: String = ""

    var street: String = ""
    var houseNumber: String = ""
    var orientationalNumber: String = ""
    var city: String = ""

    var selectedLightConditions: Set<LightType> = []

    var photos: [Photo] = []
    var note: String = ""

    var isSaving: Bool = false
    var errorMessage: String? = nil

    init() {}

    // Starts the new spot form with coordinates selected from the map.
    init(coordinates: CLLocationCoordinate2D) {
        self.coordinates = coordinates
    }

    init(spot: Spot) {
        coordinates = spot.coordinate

        name = spot.name

        street = spot.address.street
        houseNumber = spot.address.houseNumber
        orientationalNumber = spot.address.orientationalNumber ?? ""
        city = spot.address.city

        selectedLightConditions = Set(spot.lightConditions)

        photos = spot.photos
        note = spot.note ?? ""
    }
}
