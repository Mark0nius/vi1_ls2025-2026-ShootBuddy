//
//  LightType.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 13.06.2026.
//
import SwiftUI

/// The kind of light a photographer wants for a spot.
/// A spot can be tagged with several of these at once (see `Spot.lightConditions`),
/// and the route generator places the spot into a matching `LightWindow` of the day.
///
/// Raw values are stable identifiers (handy if these are mirrored into Core Data
/// as an `Int16` attribute, like `TripType`). The actual time-of-day placement
/// does **not** come from the raw value – it comes from the real sunrise/sunset
/// times computed in `LightWindow`.
enum LightType: Int16, CaseIterable, Identifiable {
    var id: Int16 { rawValue }

    case noonLight = 1
    case goldenHour = 2
    case morningLight = 3
    case blueHour = 4
    case nightLight = 5

    var name: String {
        switch self {
            case .noonLight:
                return "Noon Light"
            case .goldenHour:
                return "Golden Hour"
            case .morningLight:
                return "Morning Light"
            case .blueHour:
                return "Blue Hour"
            case .nightLight:
                return "Night Light"
        }
    }

    /// Accent colour used for the badge/icon in lists and filters.
    var color: Color {
        switch self {
            case .noonLight:
                return .orange
            case .goldenHour:
                return Color(red: 0.72, green: 0.60, blue: 0.16) // muted gold
            case .morningLight:
                return Color(red: 0.90, green: 0.83, blue: 0.10) // bright yellow
            case .blueHour:
                return .indigo
            case .nightLight:
                return Color(red: 0.36, green: 0.18, blue: 0.55) // deep purple
        }
    }

    /// SF Symbol name. Swap for your custom asset names if you prefer the
    /// illustrated icons from the design.
    var iconName: String {
        switch self {
            case .noonLight:
                return "sun.max.fill"
            case .goldenHour:
                return "hourglass"
            case .morningLight:
                return "sunrise.fill"
            case .blueHour:
                return "sunset.fill"
            case .nightLight:
                return "moon.stars.fill"
        }
    }

    /// How many times this light naturally occurs in a single day.
    /// Used by the generator to cap selections (e.g. the "maximum number of
    /// Golden Hour photoshoots" alert). Golden hour and blue hour happen twice –
    /// once around sunrise and once around sunset.
    var dailyWindowCount: Int {
        switch self {
            case .noonLight:
                return 1
            case .goldenHour:
                return 2
            case .morningLight:
                return 1
            case .blueHour:
                return 2
            case .nightLight:
                return 1
        }
    }
}



