//
//  Spot.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 13.06.2026.
//
import SwiftUI
import MapKit

/// A Czech-style postal address as captured on the New Spot screen.
/// `houseNumber` is "číslo popisné" and `orientationalNumber` is
/// "číslo orientační" – rendered together as e.g. "1984/16".
struct Address {
    var street: String
    var houseNumber: String
    var orientationalNumber: String?   // optional on the form
    var city: String

    /// e.g. "Malinovského náměstí 1984/16, Brno"
    var formatted: String {
        var line = street
        if !houseNumber.isEmpty {
            line += " \(houseNumber)"
            if let orientational = orientationalNumber, !orientational.isEmpty {
                line += "/\(orientational)"
            }
        }
        if !city.isEmpty {
            line += ", \(city)"
        }
        return line
    }
}

/// A single user-added photo for a spot. Stored as raw image data so it can be
/// persisted; convert with `Image(uiImage:)` / `UIImage(data:)` in the view.
struct Photo: Identifiable {
    var id: UUID = UUID()
    var imageData: Data
}

/// A saved location that is good for taking photos.
struct Spot: Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var address: Address
    var coordinate: CLLocationCoordinate2D

    /// The light(s) the photographer wants here. More than one may be chosen
    /// (see the Pin filter screen), which is why this is a collection.
    var lightConditions: [LightType]

    var photos: [Photo]
    var note: String?
    
    // MARK: - Equatable
    
    static func == (lhs: Spot, rhs: Spot) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}



