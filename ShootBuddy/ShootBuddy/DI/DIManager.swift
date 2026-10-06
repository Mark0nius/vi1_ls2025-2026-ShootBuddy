//
//  DIManager.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 13.06.2026.
//
import Foundation

final class DIContainer {
    typealias Resolver = () -> Any

    private var resolvers = [String: Resolver]()
    private var cache = [String: Any]()

    static let shared = DIContainer()

    init() {
        registerDependencies()
    }

    func register<T, R>(_ type: T.Type, cached: Bool = false, service: @escaping () -> R) {
        let key = String(reflecting: type)
        resolvers[key] = service

        if cached {
            cache[key] = service()
        }
    }

    func resolve<T>() -> T {
        let key = String(reflecting: T.self)

        if let cachedService = cache[key] as? T {
            print("🥣 Resolving cached instance of \(T.self).")

            return cachedService
        }

        if let resolver = resolvers[key], let service = resolver() as? T {
            print("🥣 Resolving new instance of \(T.self).")

            return service
        }

        fatalError("🥣 \(key) has not been registered.")
    }
}

extension DIContainer {
    func registerDependencies() {
        
        register(DataManaging.self, cached: true) {
            CoreDataManager()
        }
        
        register(LocationManaging.self, cached: true) {
            CoreLocationManager()
        }
        
        register(APIManaging.self, cached: true) {
            APIManager()
        }
        
        register(LightCalculating.self, cached: true) {
            LightCalculator()
        }
        
        register(RouteGenerating.self, cached: true) { [weak self] in
            guard let self = self else {
                fatalError("🥣 DIContainer deallocated during registration")
            }
            let lightCalculator: LightCalculating = self.resolve()
            let dataManager: DataManaging = self.resolve()
            return RouteGenerator(lightCalculator: lightCalculator, dataManager: dataManager)
        }
        
        //MARK - marek notifikace
        register(WeatherNotificationManager.self, cached: true) {
            WeatherNotificationManager()
        }

        register(ActiveRouteWeatherMonitor.self, cached: true) { [weak self] in
            guard let self = self else {
                fatalError("DIContainer deallocated during registration")
            }

            let apiManager: APIManaging = self.resolve()
            let dataManager: DataManaging = self.resolve()
            let notificationManager: WeatherNotificationManager = self.resolve()

            return ActiveRouteWeatherMonitor(
                apiManager: apiManager,
                dataManager: dataManager,
                notificationManager: notificationManager
            )
        }
    }
}
