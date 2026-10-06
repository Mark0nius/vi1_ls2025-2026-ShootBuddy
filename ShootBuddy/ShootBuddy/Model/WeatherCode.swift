//
//  WeatherCode.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 13.06.2026.
//
import Foundation

/// WMO weather interpretation codes returned by Open-Meteo's `weather_code`.
/// The raw value is the code itself, so it maps straight from the API:
/// `WeatherCode(rawValue: current.weatherCode)`.
enum WeatherCode: Int, CaseIterable, Identifiable {
    var id: Int { rawValue }

    case clearSky = 0
    case mainlyClear = 1
    case partlyCloudy = 2
    case overcast = 3
    case fog = 45
    case depositingRimeFog = 48
    case lightDrizzle = 51
    case moderateDrizzle = 53
    case denseDrizzle = 55
    case lightFreezingDrizzle = 56
    case denseFreezingDrizzle = 57
    case slightRain = 61
    case moderateRain = 63
    case heavyRain = 65
    case lightFreezingRain = 66
    case heavyFreezingRain = 67
    case slightSnowfall = 71
    case moderateSnowfall = 73
    case heavySnowfall = 75
    case snowGrains = 77
    case slightRainShowers = 80
    case moderateRainShowers = 81
    case violentRainShowers = 82
    case slightSnowShowers = 85
    case heavySnowShowers = 86
    case thunderstorm = 95
    case thunderstormSlightHail = 96
    case thunderstormHeavyHail = 99

    /// The actual weather name to show in the app.
    var name: String {
        switch self {
            case .clearSky:               return "Clear sky"
            case .mainlyClear:            return "Mainly clear"
            case .partlyCloudy:           return "Partly cloudy"
            case .overcast:               return "Overcast"
            case .fog:                    return "Fog"
            case .depositingRimeFog:      return "Depositing rime fog"
            case .lightDrizzle:           return "Light drizzle"
            case .moderateDrizzle:        return "Moderate drizzle"
            case .denseDrizzle:           return "Dense drizzle"
            case .lightFreezingDrizzle:   return "Light freezing drizzle"
            case .denseFreezingDrizzle:   return "Dense freezing drizzle"
            case .slightRain:             return "Slight rain"
            case .moderateRain:           return "Moderate rain"
            case .heavyRain:              return "Heavy rain"
            case .lightFreezingRain:      return "Light freezing rain"
            case .heavyFreezingRain:      return "Heavy freezing rain"
            case .slightSnowfall:         return "Slight snowfall"
            case .moderateSnowfall:       return "Moderate snowfall"
            case .heavySnowfall:          return "Heavy snowfall"
            case .snowGrains:             return "Snow grains"
            case .slightRainShowers:      return "Slight rain showers"
            case .moderateRainShowers:    return "Moderate rain showers"
            case .violentRainShowers:     return "Violent rain showers"
            case .slightSnowShowers:      return "Slight snow showers"
            case .heavySnowShowers:       return "Heavy snow showers"
            case .thunderstorm:           return "Thunderstorm"
            case .thunderstormSlightHail: return "Thunderstorm with slight hail"
            case .thunderstormHeavyHail:  return "Thunderstorm with heavy hail"
        }
    }

    /// SF Symbol for the weather report card / notification.
    var iconName: String {
        switch self {
            case .clearSky:
                return "sun.max.fill"
            case .mainlyClear, .partlyCloudy:
                return "cloud.sun.fill"
            case .overcast:
                return "cloud.fill"
            case .fog, .depositingRimeFog:
                return "cloud.fog.fill"
            case .lightDrizzle, .moderateDrizzle, .denseDrizzle:
                return "cloud.drizzle.fill"
            case .lightFreezingDrizzle, .denseFreezingDrizzle,
                 .lightFreezingRain, .heavyFreezingRain:
                return "cloud.sleet.fill"
            case .slightRain, .moderateRain, .heavyRain:
                return "cloud.rain.fill"
            case .slightRainShowers, .moderateRainShowers, .violentRainShowers:
                return "cloud.heavyrain.fill"
            case .slightSnowfall, .moderateSnowfall, .heavySnowfall,
                 .snowGrains, .slightSnowShowers, .heavySnowShowers:
                return "cloud.snow.fill"
            case .thunderstorm, .thunderstormSlightHail, .thunderstormHeavyHail:
                return "cloud.bolt.rain.fill"
        }
    }
}

//MARK - marek notifikace
extension WeatherCode {
    var shouldNotifyPhotographer: Bool {
        switch self {
        case .overcast,
             .fog,
             .depositingRimeFog,
             .lightDrizzle,
             .moderateDrizzle,
             .denseDrizzle,
             .lightFreezingDrizzle,
             .denseFreezingDrizzle,
             .slightRain,
             .moderateRain,
             .heavyRain,
             .lightFreezingRain,
             .heavyFreezingRain,
             .slightSnowfall,
             .moderateSnowfall,
             .heavySnowfall,
             .snowGrains,
             .slightRainShowers,
             .moderateRainShowers,
             .violentRainShowers,
             .slightSnowShowers,
             .heavySnowShowers,
             .thunderstorm,
             .thunderstormSlightHail,
             .thunderstormHeavyHail:
            return true

        case .clearSky,
                .mainlyClear,
                .partlyCloudy:
            return false
        }
    }
}
