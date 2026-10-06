//
//  ActiveWeatherRouterMonitor.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 17.06.2026.
//
import CoreLocation

final class ActiveRouteWeatherMonitor {
    private let apiManager: APIManaging
    private let dataManager: DataManaging
    private let notificationManager: WeatherNotificationManager

    init(
        apiManager: APIManaging,
        dataManager: DataManaging,
        notificationManager: WeatherNotificationManager
    ) {
        self.apiManager = apiManager
        self.dataManager = dataManager
        self.notificationManager = notificationManager
    }

    // Asks the user for notification permission through the notification manager.
    func requestNotificationPermission() async {
        await notificationManager.requestPermission()
    }

    // Checks the currently active route and sends a notification if the current spot has bad weather.
    func checkActiveRouteWeather() async {
        let routes = dataManager.fetchRoutes()

        guard
            let activeRoute = routes.first(where: { $0.status == .inProgress }),
            let currentStop = activeRoute.currentStop
        else {
            return
        }

        let spot = currentStop.spot

        do {
            let endpoint = WeatherDataRouter.weather(
                long: spot.coordinate.longitude,
                lat: spot.coordinate.latitude
            )

            let weatherData: WeatherData = try await apiManager.request(endpoint)

            guard let weather = weatherData.current.condition else {
                return
            }

            guard weather.shouldNotifyPhotographer else {
                return
            }

            await notificationManager.sendWeatherAlert(
                for: spot,
                weather: weather
            )
        } catch {
            print("Active route weather check error: \(error)")
        }
    }
}
