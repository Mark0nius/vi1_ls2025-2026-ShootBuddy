//
//  MapViewState.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//

import SwiftUI
import MapKit

@Observable
class MapViewState {
    var cameraPosition: MapCameraPosition = .camera(
        .init(
            centerCoordinate: .init(latitude: 49.1951, longitude: 16.6068),
            distance: 6000
        )
    )

    var spots: [Spot] = []
    var selectedSpot: Spot? = nil
    var newSpotDraft: MapSpotDraft? = nil
    var longPressLocation: CGPoint? = nil

    var selectedMapStyle: ShootBuddyMapStyle = .standard
}

// Temporary map selection used to present the new spot sheet.
struct MapSpotDraft: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

enum ShootBuddyMapStyle: CaseIterable, Identifiable {
    case standard
    case hybrid
    case imagery

    var id: Self { self }

    var title: String {
        switch self {
            case .standard:
                return "Standard"
            case .hybrid:
                return "Hybrid"
            case .imagery:
                return "Satellite"
        }
    }

    var iconName: String {
        switch self {
            case .standard:
                return "map"
            case .hybrid:
                return "map.fill"
            case .imagery:
                return "globe.europe.africa.fill"
        }
    }

    var mapStyle: MapStyle {
        switch self {
            case .standard:
                return .standard

            case .hybrid:
                return .hybrid

            case .imagery:
                return .imagery
        }
    }
}
