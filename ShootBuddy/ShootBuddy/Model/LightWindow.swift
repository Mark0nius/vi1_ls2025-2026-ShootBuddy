//
//  LightWindow.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 13.06.2026.
//
import Foundation
import CoreLocation

/// A concrete time interval on a specific day during which a given `LightType`
/// occurs at a given location – e.g. "Golden Hour, 05:10–05:55".
///
/// These are not entered by the user; they are calculated from the route's date
/// and coordinates using a sun-position calculator (sunrise/sunset/twilight
/// times). The route generator then matches each spot's `lightConditions`
/// against the day's available windows and slots the spot in.
///
/// Suggested derivation per window:
///  - morningLight: civil dawn  →  sunrise
///  - goldenHour:   sunrise      →  sunrise + ~1h   AND   sunset − ~1h → sunset
///  - noonLight:    around solar noon
///  - blueHour:     sunset       →  civil dusk      AND   civil dawn − blue band
///  - nightLight:   after astronomical dusk
struct LightWindow: Identifiable {
    var id: UUID = UUID()
    var lightType: LightType
    var start: Date
    var end: Date

    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }

    /// Whether a moment falls inside this window.
    func contains(_ date: Date) -> Bool {
        date >= start && date <= end
    }

    /// Whether a [from, to] block fits entirely inside this window.
    func canFit(from: Date, to: Date) -> Bool {
        from >= start && to <= end
    }
}


