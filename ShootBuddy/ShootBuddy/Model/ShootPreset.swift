//
//  ShootPreset.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 13.06.2026.
//
import Foundation
import MapKit

/// A reusable timing template (Settings → Presets). It tells the generator how
/// long a single spot occupies, so it can size each stop's block and leave
/// realistic gaps. All values are in minutes (as shown: "30 min", "120 min").
struct ShootPreset: Identifiable {
    var id: UUID = UUID()
    var name: String

    var setUpMinutes: Int       // "Set up time" (required)
    var averageShootMinutes: Int // "Average shoot time"
    var packUpMinutes: Int      // "Pack up time" (required)

    /// Total minutes reserved at one spot.
    var totalMinutes: Int {
        setUpMinutes + averageShootMinutes + packUpMinutes
    }

    /// Total time block as a `TimeInterval`, convenient for date math when
    /// computing a stop's `departureTime` from its `arrivalTime`.
    var slotDuration: TimeInterval {
        TimeInterval(totalMinutes * 60)
    }
}

enum TransportMode: String, CaseIterable, Codable, Identifiable {
    case driving = "Driving"
    case walking = "Walking"
    
    var id: String { rawValue }
    
    var mkDirectionsType: MKDirectionsTransportType {
        switch self {
        case .driving: return .automobile
        case .walking: return .walking
        }
    }
    
    var icon: String {
        switch self {
        case .driving: return "car.fill"
        case .walking: return "figure.walk"
        }
    }
}

/// App-wide settings. Holds the saved presets and which one is active
/// ("Current preset" dropdown on the Settings screen).
struct AppSettings {
    var presets: [ShootPreset]
    var currentPresetID: UUID?

    var currentPreset: ShootPreset? {
        guard let id = currentPresetID else { return presets.first }
        return presets.first { $0.id == id } ?? presets.first
    }
}



