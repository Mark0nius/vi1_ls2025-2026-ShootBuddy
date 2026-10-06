//
//  LightCalculator.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 16.06.2026.
//

import Foundation
import CoreLocation
import Solar

/// Service for calculating light conditions (golden hour, blue hour, etc.) for a given location and date
/// Uses Sunrise-Sunset.org API for accurate times, with Solar.swift as offline fallback
final class LightCalculator: LightCalculating {
    
    private let sunriseSunsetService = SunriseSunsetService()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
    
    /// Calculates all light windows for a given date and location
    /// - Parameters:
    ///   - date: The date to calculate light windows for
    ///   - coordinate: The geographic coordinate (lat/lon)
    /// - Returns: Array of LightWindow objects representing available light conditions
    func calculateLightWindows(for date: Date, at coordinate: CLLocationCoordinate2D) async -> [LightWindow] {
        var windows: [LightWindow] = []
        
        // Get the calendar day start and end
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return windows
        }
        
        print("🌅 Solar Events for \(formatDate(date)) at (\(coordinate.latitude), \(coordinate.longitude)):")
        print("  📍 Coordinates: \(coordinate.latitude)°N, \(coordinate.longitude)°E")
        print("  📅 Date: \(date)")
        print("  🕐 Timezone: \(TimeZone.current.identifier) (UTC\(TimeZone.current.secondsFromGMT(for: date) / 3600))")
        print("")
        
        // Try to use Sunrise-Sunset API for accurate times
        let solarTimes = Task {
            try? await sunriseSunsetService.getSolarTimes(for: date, at: coordinate)
        }
        
        let apiResults = await solarTimes.value
        
        let sunrise: Date?
        let sunset: Date?
        let civilSunrise: Date?
        let civilSunset: Date?
        let nauticalSunrise: Date?
        let nauticalSunset: Date?
        let astronomicalSunrise: Date?
        let astronomicalSunset: Date?
        
        if let results = apiResults {
            // Use API results (most accurate!)
            print("  ✅ Using Sunrise-Sunset.org API (accurate times)")
            sunrise = sunriseSunsetService.parseISODate(results.sunrise)
            sunset = sunriseSunsetService.parseISODate(results.sunset)
            civilSunrise = sunriseSunsetService.parseISODate(results.civilTwilightBegin)
            civilSunset = sunriseSunsetService.parseISODate(results.civilTwilightEnd)
            nauticalSunrise = sunriseSunsetService.parseISODate(results.nauticalTwilightBegin)
            nauticalSunset = sunriseSunsetService.parseISODate(results.nauticalTwilightEnd)
            
            // Parse astronomical times, but validate they're on the correct day
            // At high latitudes in summer, these might be on the wrong day or invalid
            astronomicalSunrise = results.astronomicalTwilightBegin.flatMap { 
                guard let date = sunriseSunsetService.parseISODate($0),
                      calendar.isDate(date, inSameDayAs: dayStart) else {
                    return nil
                }
                return date
            }
            astronomicalSunset = results.astronomicalTwilightEnd.flatMap { 
                guard let date = sunriseSunsetService.parseISODate($0),
                      calendar.isDate(date, inSameDayAs: dayStart) else {
                    return nil
                }
                return date
            }
        } else {
            // Fallback to Solar.swift (offline mode)
            print("  ⚠️  API unavailable, using Solar.swift (offline mode - less accurate)")
            guard let solar = Solar(for: date, coordinate: coordinate) else {
                print("  ❌ Could not create Solar object")
                return windows
            }
            
            sunrise = solar.sunrise
            sunset = solar.sunset
            civilSunrise = solar.civilSunrise
            civilSunset = solar.civilSunset
            nauticalSunrise = solar.nauticalSunrise
            nauticalSunset = solar.nauticalSunset
            astronomicalSunrise = solar.astronomicalSunrise
            astronomicalSunset = solar.astronomicalSunset
        }
        
        // Print solar events
        if let astronomicalSunrise = astronomicalSunrise {
            print("  Astronomical Dawn: \(formatTime(astronomicalSunrise))")
        }
        if let nauticalSunrise = nauticalSunrise {
            print("  Nautical Dawn: \(formatTime(nauticalSunrise))")
        }
        if let civilSunrise = civilSunrise {
            print("  Civil Dawn: \(formatTime(civilSunrise))")
        }
        if let sunrise = sunrise {
            print("  ☀️ Sunrise: \(formatTime(sunrise))")
        }
        if let sunrise = sunrise, let sunset = sunset {
            let solarNoon = Date(timeIntervalSince1970: (sunrise.timeIntervalSince1970 + sunset.timeIntervalSince1970) / 2)
            print("  Solar Noon: \(formatTime(solarNoon))")
        }
        if let sunset = sunset {
            print("  🌇 Sunset: \(formatTime(sunset))")
        }
        if let civilSunset = civilSunset {
            print("  Civil Dusk: \(formatTime(civilSunset))")
        }
        if let nauticalSunset = nauticalSunset {
            print("  Nautical Dusk: \(formatTime(nauticalSunset))")
        }
        if let astronomicalSunset = astronomicalSunset {
            print("  Astronomical Dusk: \(formatTime(astronomicalSunset))")
        }
        print("")
        
        // MORNING BLUE HOUR (civil dawn to sunrise)
        if let civilSunrise = civilSunrise,
           let sunrise = sunrise {
            windows.append(LightWindow(
                lightType: .blueHour,
                start: civilSunrise,
                end: sunrise
            ))
        }
        
        // MORNING GOLDEN HOUR (sunrise to sun 6° above horizon)
        if let sunrise = sunrise {
            let goldenHourEnd = sunrise.addingTimeInterval(60 * 60)
            windows.append(LightWindow(
                lightType: .goldenHour,
                start: sunrise,
                end: goldenHourEnd
            ))
        }
        
        // MORNING LIGHT (after golden hour until noon light starts)
        if let sunrise = sunrise,
           let sunset = sunset {
            let morningStart = sunrise.addingTimeInterval(60 * 60)
            let solarNoon = Date(timeIntervalSince1970: (sunrise.timeIntervalSince1970 + sunset.timeIntervalSince1970) / 2)
            let morningEnd = solarNoon.addingTimeInterval(-2 * 60 * 60)
            
            if morningEnd > morningStart {
                windows.append(LightWindow(
                    lightType: .morningLight,
                    start: morningStart,
                    end: morningEnd
                ))
            }
        }
        
        // NOON LIGHT (around solar noon, ±2 hours)
        if let sunrise = sunrise,
           let sunset = sunset {
            let solarNoon = Date(timeIntervalSince1970: (sunrise.timeIntervalSince1970 + sunset.timeIntervalSince1970) / 2)
            let noonStart = solarNoon.addingTimeInterval(-2 * 60 * 60)
            let noonEnd = solarNoon.addingTimeInterval(2 * 60 * 60)
            windows.append(LightWindow(
                lightType: .noonLight,
                start: noonStart,
                end: noonEnd
            ))
        }
        
        // EVENING GOLDEN HOUR (sun 6° above horizon to sunset)
        if let sunset = sunset {
            let goldenHourStart = sunset.addingTimeInterval(-60 * 60)
            windows.append(LightWindow(
                lightType: .goldenHour,
                start: goldenHourStart,
                end: sunset
            ))
        }
        
        // EVENING BLUE HOUR (sunset to civil dusk)
        if let sunset = sunset,
           let civilSunset = civilSunset {
            windows.append(LightWindow(
                lightType: .blueHour,
                start: sunset,
                end: civilSunset
            ))
        }
        
        // NIGHT LIGHT (after astronomical dusk until next astronomical dawn)
        if let astronomicalSunset = astronomicalSunset {
            // Get next day's times
            let nextDayTask = Task {
                try? await sunriseSunsetService.getSolarTimes(for: dayEnd, at: coordinate)
            }
            
            if let nextResults = await nextDayTask.value,
               let astroBeginString = nextResults.astronomicalTwilightBegin,
               !astroBeginString.isEmpty {
                let nextAstronomicalSunrise = sunriseSunsetService.parseISODate(astroBeginString)
                
                // Create night light window
                // Note: nextAstronomicalSunrise might be on the next day (which is correct)
                // or might be nil if astronomical twilight doesn't occur
                if let nextSunrise = nextAstronomicalSunrise {
                    windows.append(LightWindow(
                        lightType: .nightLight,
                        start: astronomicalSunset,
                        end: nextSunrise
                    ))
                } else {
                    // If no astronomical dawn next day, use end of next day as fallback
                    print("  ℹ️  No astronomical dawn tomorrow (polar summer)")
                    print("     Creating night window until end of next day")
                    windows.append(LightWindow(
                        lightType: .nightLight,
                        start: astronomicalSunset,
                        end: dayEnd
                    ))
                }
            } else {
                // Couldn't fetch next day's data - use a reasonable default (6 hours)
                print("  ⚠️  Could not fetch next day's astronomical data")
                print("     Creating 6-hour night window as fallback")
                windows.append(LightWindow(
                    lightType: .nightLight,
                    start: astronomicalSunset,
                    end: astronomicalSunset.addingTimeInterval(6 * 60 * 60)
                ))
            }
        } else {
            // Fallback: use nautical dusk (astronomical twilight doesn't occur in summer)
            print("  ℹ️  Astronomical twilight doesn't occur (summer/high latitude)")
            print("     Using nautical twilight for night light instead")
            
            if let nauticalSunset = nauticalSunset {
                let nextDayTask = Task {
                    try? await sunriseSunsetService.getSolarTimes(for: dayEnd, at: coordinate)
                }
                
                if let nextResults = await nextDayTask.value,
                   let nextNauticalSunrise = sunriseSunsetService.parseISODate(nextResults.nauticalTwilightBegin) {
                    // Valid nautical twilight window
                    // Ensure it's actually after nautical sunset (crosses midnight correctly)
                    let nightEnd = nextNauticalSunrise > nauticalSunset ? nextNauticalSunrise : dayEnd
                    windows.append(LightWindow(
                        lightType: .nightLight,
                        start: nauticalSunset,
                        end: nightEnd
                    ))
                } else {
                    // Fallback: 6-hour night window
                    print("  ⚠️  Could not fetch next nautical dawn")
                    print("     Creating 6-hour night window as fallback")
                    windows.append(LightWindow(
                        lightType: .nightLight,
                        start: nauticalSunset,
                        end: nauticalSunset.addingTimeInterval(6 * 60 * 60)
                    ))
                }
            }
        }
        
        return windows.sorted { $0.start < $1.start }
    }
    
    /// Finds the next occurrence of a specific light type starting from a given time
    /// - Parameters:
    ///   - lightType: The type of light to find
    ///   - startTime: When to start searching
    ///   - coordinate: Location coordinates
    /// - Returns: The next available light window, if any
    func nextWindow(for lightType: LightType, after startTime: Date, at coordinate: CLLocationCoordinate2D) async -> LightWindow? {
        // Check current day
        let currentDayWindows = await calculateLightWindows(for: startTime, at: coordinate)
        if let window = currentDayWindows.first(where: { $0.lightType == lightType && $0.end > startTime }) {
            return window
        }
        
        // Check next day
        let calendar = Calendar.current
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: startTime) {
            let nextDayWindows = await calculateLightWindows(for: nextDay, at: coordinate)
            return nextDayWindows.first(where: { $0.lightType == lightType })
        }
        
        return nil
    }
}

