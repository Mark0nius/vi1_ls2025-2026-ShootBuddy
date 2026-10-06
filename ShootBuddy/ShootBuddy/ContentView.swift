//
//  ContentView.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 13.06.2026.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @State private var listViewModel = ListViewModel()
    @State private var mapViewModel = MapViewModel()
    @State private var settingsViewModel = SettingsViewModel()
    @State private var calendarViewModel = CalendarViewModel()

    @State private var selectedTab: AppTab = .list
    
    private let weatherMonitor: ActiveRouteWeatherMonitor = DIContainer.shared.resolve()

    var body: some View {
        VStack(spacing: 0) {
            
            /*
            Button("Test Rain Notification") {
                Task {
                    let notificationManager: WeatherNotificationManager = DIContainer.shared.resolve()

                    await notificationManager.requestPermission()

                    await notificationManager.sendWeatherAlert(
                        for: Spot(
                            name: "Fake Rain Spot",
                            address: Address(
                                street: "Test",
                                houseNumber: "1",
                                city: "Brno"
                            ),
                            coordinate: CLLocationCoordinate2D(
                                latitude: 49.1951,
                                longitude: 16.6068
                            ),
                            lightConditions: [],
                            photos: [],
                            note: nil
                        ),
                        weather: .moderateRain
                    )
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
             */
            
            
            TabView(selection: $selectedTab) {
                Tab("List", systemImage: "list.bullet", value: AppTab.list) {
                    ListView(viewModel: listViewModel)
                }

                Tab("Map", systemImage: "map", value: AppTab.map) {
                    MapView(viewModel: mapViewModel)
                }

                Tab("Calendar", systemImage: "calendar", value: AppTab.calendar) {
                    CalendarView(viewModel: calendarViewModel)
                }

                Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                    SettingsView(viewModel: settingsViewModel)
                }
            }
            .tint(.primary)
        }
        .task {
            await weatherMonitor.requestNotificationPermission()
            await weatherMonitor.checkActiveRouteWeather()
        }
    }
}

// MARK: - Tabs

enum AppTab: Hashable {
    case list
    case map
    case calendar
    case settings
}

// MARK: - Placeholder

private struct PlaceholderTab: View {
    let title: String
    let icon: String
    let message: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                title,
                systemImage: icon,
                description: Text(message)
            )
            .navigationTitle(title)
        }
    }
}

#Preview {
    ContentView()
}
