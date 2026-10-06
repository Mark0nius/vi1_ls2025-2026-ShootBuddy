//
//  Untitled.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//
import SwiftUI
import MapKit
import PhotosUI

@Observable
class SpotAddViewModel {
    var state: SpotAddViewState

    private var dataManager: DataManaging
    private var locationManager: LocationManaging
    private var editedSpot: Spot?
    private var usesPinnedCoordinate: Bool

    var isEditing: Bool {
        editedSpot != nil
    }

    var title: String {
        isEditing ? "Edit Spot" : "New Spot"
    }

    var canSave: Bool {
        !trimmed(state.name).isEmpty &&
        !trimmed(state.street).isEmpty &&
        !trimmed(state.houseNumber).isEmpty &&
        !trimmed(state.city).isEmpty &&
        !state.selectedLightConditions.isEmpty &&
        !state.isSaving
    }

    init(spot: Spot? = nil) {
        dataManager = DIContainer.shared.resolve()
        locationManager = DIContainer.shared.resolve()
        editedSpot = spot
        usesPinnedCoordinate = false

        if let spot {
            state = SpotAddViewState(spot: spot)
        } else {
            state = SpotAddViewState()
        }
    }

    // Creates a new spot form from a coordinate picked on the map.
    init(coordinates: CLLocationCoordinate2D) {
        dataManager = DIContainer.shared.resolve()
        locationManager = DIContainer.shared.resolve()
        editedSpot = nil
        usesPinnedCoordinate = true
        state = SpotAddViewState(coordinates: coordinates)
    }

    // Saves the current spot form into persistent storage.
    func saveSpot() async -> Bool {
        guard canSave else {
            print("Missing required fields")
            return false
        }

        state.isSaving = true
        state.errorMessage = nil

        if !usesPinnedCoordinate {
            guard await resolveCoordinatesFromAddress() else {
                state.isSaving = false
                state.errorMessage = "Address could not be found."
                print("Wrong address")
                return false
            }
        }

        let newSpot = Spot(
            id: editedSpot?.id ?? UUID(),
            name: trimmed(state.name),
            address: createAddress(),
            coordinate: state.coordinates,
            lightConditions: sortedSelectedLightConditions(),
            photos: state.photos,
            note: trimmed(state.note).isEmpty ? nil : trimmed(state.note)
        )

        dataManager.saveSpot(newSpot)
        editedSpot = newSpot

        state.isSaving = false
        return true
    }

    // Fills street, house number, orientational number, and city from the pinned map coordinate.
    func fillAddressFromPinnedCoordinate() async {
        guard usesPinnedCoordinate, !isEditing else {
            return
        }

        guard let address = await locationManager.translateCoordinatesToAddress(state.coordinates) else {
            return
        }

        if trimmed(state.street).isEmpty {
            state.street = address.street
        }

        if trimmed(state.houseNumber).isEmpty {
            state.houseNumber = address.houseNumber
        }

        if trimmed(state.orientationalNumber).isEmpty {
            state.orientationalNumber = address.orientationalNumber ?? ""
        }

        if trimmed(state.city).isEmpty {
            state.city = address.city
        }
    }

    // Deletes the currently edited spot from persistent storage.
    func deleteSpot() -> Bool {
        guard let editedSpot else {
            return false
        }

        dataManager.deleteSpot(editedSpot)
        return true
    }

    // Adds or removes a light condition from the spot form.
    func toggleLightCondition(_ light: LightType) {
        if state.selectedLightConditions.contains(light) {
            state.selectedLightConditions.remove(light)
        } else {
            state.selectedLightConditions.insert(light)
        }
    }

    // Loads selected photos from the photo picker into the spot form.
    func addPhotos(from items: [PhotosPickerItem]) async {
        for item in items {
            guard let imageData = try? await item.loadTransferable(type: Data.self) else {
                continue
            }

            state.photos.append(Photo(imageData: imageData))
        }
    }

    // Removes a photo from the spot form.
    func removePhoto(_ photo: Photo) {
        state.photos.removeAll { $0.id == photo.id }
    }

    // Resolves the typed address into coordinates for spots created from the normal form.
    func resolveCoordinatesFromAddress() async -> Bool {
        let address = createAddress()

        if let editedSpot,
           editedSpot.address.formatted == address.formatted {
            state.coordinates = editedSpot.coordinate
            return true
        }

        guard let coordinates = await locationManager.translateAdressToCoordinates(address.formatted) else {
            print("Invalid address")
            return false
        }

        state.coordinates = coordinates
        return true
    }

    private func createAddress() -> Address {
        Address(
            street: trimmed(state.street),
            houseNumber: trimmed(state.houseNumber),
            orientationalNumber: trimmed(state.orientationalNumber).isEmpty
                ? nil
                : trimmed(state.orientationalNumber),
            city: trimmed(state.city)
        )
    }

    private func sortedSelectedLightConditions() -> [LightType] {
        state.selectedLightConditions.sorted { first, second in
            first.rawValue < second.rawValue
        }
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
