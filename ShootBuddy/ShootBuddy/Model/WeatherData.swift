//
//  WeatherData.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 13.06.2026.
//
import Foundation

/// Top-level response from Open-Meteo:
/// https://api.open-meteo.com/v1/forecast?latitude=…&longitude=…&current=weather_code
struct WeatherData: Decodable {
    let current: Current
}

struct Current: Decodable {
    let weatherCode: Int

    enum CodingKeys: String, CodingKey {
        case weatherCode = "weather_code"
    }

    /// The decoded WMO code as a typed condition (nil if the API ever returns
    /// a code we don't recognise).
    var condition: WeatherCode? {
        WeatherCode(rawValue: weatherCode)
    }

    /// Human-readable weather name for the report card, e.g. "Partly cloudy".
    var conditionName: String {
        condition?.name ?? "Unknown"
    }
}

