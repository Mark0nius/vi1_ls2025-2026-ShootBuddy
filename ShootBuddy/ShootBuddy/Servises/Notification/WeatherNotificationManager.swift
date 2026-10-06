//
//  WeatherNotificationManager.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 17.06.2026.
//

import UserNotifications

final class WeatherNotificationManager {
    
    // Asks the user for permission to show local notifications.
    func requestPermission() async {
        do {
            try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    // Sends an immediate local notification with the bad weather warning.
    func sendWeatherAlert(for spot: Spot, weather: WeatherCode) async {
        let content = UNMutableNotificationContent()
        content.title = "Weather warning"
        content.body = "\(spot.name): \(weather.name). Check if the shoot still makes sense."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "weather-\(spot.id.uuidString)-\(weather.rawValue)",
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Notification scheduling error: \(error)")
        }
    }
}
