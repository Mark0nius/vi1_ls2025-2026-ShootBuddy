//
//  CoreLocationManager.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//
import CoreLocation

class CoreLocationManager: NSObject, LocationManaging, CLLocationManagerDelegate {
   
    private var locationManager: CLLocationManager!
    private var currentLocation: CLLocationCoordinate2D? = nil
    
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.first {
            self.currentLocation = currentLocation.coordinate
        }
    }
    
    func getCurrentLocation() -> CLLocationCoordinate2D? {
        return currentLocation
    }
    
    func translateCoordinatesToAdress(_ coordinates: CLLocationCoordinate2D) async -> String? {
        let geocoder = CLGeocoder()
        let location = CLLocation(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude
        )

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(
                location,
                preferredLocale: Locale(identifier: "cs_CZ")
            )

            guard let firstPlacemark = placemarks.first else {
                print("No placemark found")
                return nil
            }
            
            return firstPlacemark.locality ?? firstPlacemark.name
        } catch {
            print("Reverse geocode failed: \(error.localizedDescription)")
            return nil
        }
    }

    // Converts map coordinates into editable address fields for the new spot form.
    func translateCoordinatesToAddress(_ coordinates: CLLocationCoordinate2D) async -> Address? {
        let geocoder = CLGeocoder()
        let location = CLLocation(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude
        )

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(
                location,
                preferredLocale: Locale(identifier: "cs_CZ")
            )

            guard let placemark = placemarks.first else {
                print("No placemark found")
                return nil
            }

            let street = placemark.thoroughfare ?? fallbackStreet(from: placemark.name) ?? ""
            let houseNumberValue = placemark.subThoroughfare ?? fallbackHouseNumber(from: placemark.name)
            let houseNumbers = splitHouseNumber(houseNumberValue)

            return Address(
                street: street,
                houseNumber: houseNumbers.houseNumber,
                orientationalNumber: houseNumbers.orientationalNumber,
                city: placemark.locality ?? placemark.subAdministrativeArea ?? ""
            )
        } catch {
            print("Reverse geocode failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func translateAdressToCoordinates(_ address: String) async -> CLLocationCoordinate2D? {
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.geocodeAddressString(address)

            guard let firstPlacemark = placemarks.first,
                  let location = firstPlacemark.location else {
                print("No placemark found")
                return nil
            }

            print("Placemark: \(firstPlacemark)")
            return location.coordinate

        } catch {
            print("Geocode failed: \(error.localizedDescription)")
            return nil
        }
    }

    // Splits Czech house numbers like "1984/16" into house and orientational parts.
    private func splitHouseNumber(_ value: String?) -> (houseNumber: String, orientationalNumber: String?) {
        guard let value, !value.isEmpty else {
            return ("", nil)
        }

        let parts = value.split(separator: "/", maxSplits: 1).map(String.init)

        return (
            houseNumber: parts.first ?? value,
            orientationalNumber: parts.count > 1 ? parts[1] : nil
        )
    }

    // Extracts a street name from a placemark name when CLPlacemark has no thoroughfare.
    private func fallbackStreet(from name: String?) -> String? {
        guard let name else {
            return nil
        }

        let parts = name.split(separator: " ").map(String.init)
        guard parts.count > 1 else {
            return name
        }

        return parts.dropLast().joined(separator: " ")
    }

    // Extracts a house number from a placemark name when CLPlacemark has no subThoroughfare.
    private func fallbackHouseNumber(from name: String?) -> String? {
        guard let lastPart = name?.split(separator: " ").last else {
            return nil
        }

        let value = String(lastPart)
        return value.contains { $0.isNumber } ? value : nil
    }
}
