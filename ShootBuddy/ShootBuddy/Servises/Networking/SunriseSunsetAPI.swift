//
//  SunriseSunsetAPI.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 16.06.2026.
//

import Foundation
import CoreLocation

/// Response from sunrise-sunset.org API
struct SunriseSunsetResponse: Decodable {
    let results: SunriseSunsetResults
    let status: String
}

struct SunriseSunsetResults: Decodable {
    let sunrise: String
    let sunset: String
    let solarNoon: String
    let civilTwilightBegin: String
    let civilTwilightEnd: String
    let nauticalTwilightBegin: String
    let nauticalTwilightEnd: String
    let astronomicalTwilightBegin: String?
    let astronomicalTwilightEnd: String?
    
    enum CodingKeys: String, CodingKey {
        case sunrise
        case sunset
        case solarNoon = "solar_noon"
        case civilTwilightBegin = "civil_twilight_begin"
        case civilTwilightEnd = "civil_twilight_end"
        case nauticalTwilightBegin = "nautical_twilight_begin"
        case nauticalTwilightEnd = "nautical_twilight_end"
        case astronomicalTwilightBegin = "astronomical_twilight_begin"
        case astronomicalTwilightEnd = "astronomical_twilight_end"
    }
}

/// Service for fetching accurate solar times from sunrise-sunset.org API
actor SunriseSunsetService {
    private var cache: [String: SunriseSunsetResults] = [:]
    
    func getSolarTimes(for date: Date, at coordinate: CLLocationCoordinate2D) async throws -> SunriseSunsetResults {
        let cacheKey = makeCacheKey(date: date, coordinate: coordinate)
        
        // Return cached value if available
        if let cached = cache[cacheKey] {
            print("  💾 Using cached solar data")
            return cached
        }
        
        // Fetch from API
        let dateString = formatDateForAPI(date)
        let urlString = "https://api.sunrise-sunset.org/json?lat=\(coordinate.latitude)&lng=\(coordinate.longitude)&date=\(dateString)&formatted=0"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "SunriseSunsetService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        print("  🌐 Fetching solar data from API...")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "SunriseSunsetService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(SunriseSunsetResponse.self, from: data)
        
        guard apiResponse.status == "OK" else {
            throw NSError(domain: "SunriseSunsetService", code: -3, userInfo: [NSLocalizedDescriptionKey: "API returned error status"])
        }
        
        // Cache the results
        cache[cacheKey] = apiResponse.results
        
        print("  ✅ Successfully fetched solar data from API")
        return apiResponse.results
    }
    
    private func makeCacheKey(date: Date, coordinate: CLLocationCoordinate2D) -> String {
        let dateString = formatDateForAPI(date)
        let latString = String(format: "%.4f", coordinate.latitude)
        let lonString = String(format: "%.4f", coordinate.longitude)
        return "\(dateString)_\(latString)_\(lonString)"
    }
    
    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
    
    // Not async - simple date parsing
    nonisolated func parseISODate(_ isoString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: isoString) ?? {
            // Fallback without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: isoString)
        }()
    }
}
