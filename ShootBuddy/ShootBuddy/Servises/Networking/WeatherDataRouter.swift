//
//  WeatherDataRouter.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 13.06.2026.
//
import Foundation

enum WeatherDataRouter {
    case weather(long: Double, lat: Double)
}

// if you want to see API documentation, open `open-meteo.com`
//https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41&current=weather_code

extension WeatherDataRouter: Router {
    var host: String {
        "https://api.open-meteo.com"
    }
    
    var path: String {
        "v1/forecast"
    }
    
    var method: HttpMethod {
        switch self {
        case .weather:
            .get
        }
    }
    
    var urlParameters: [String : Any]? {
        switch self {
        case let .weather(long: long, lat: lat):
            [
                "longitude": long,
                "latitude": lat,
                "current": "weather_code"
            ]
        }
    }
    
    var headers: [String : String] {
        switch self {
        case .weather:
            [:]
        }
    }
}
