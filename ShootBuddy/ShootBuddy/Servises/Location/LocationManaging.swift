//
//  LocationManaging.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//
import SwiftUI
import CoreLocation

protocol LocationManaging {
    func getCurrentLocation() -> CLLocationCoordinate2D?
    func translateCoordinatesToAdress(_ coordinates: CLLocationCoordinate2D) async -> String?

    // Converts coordinates into editable address fields for forms.
    func translateCoordinatesToAddress(_ coordinates: CLLocationCoordinate2D) async -> Address?

    func translateAdressToCoordinates(_ address: String) async -> CLLocationCoordinate2D?
}
