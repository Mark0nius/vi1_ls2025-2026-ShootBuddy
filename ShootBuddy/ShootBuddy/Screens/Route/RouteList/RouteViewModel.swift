//
//  RouteViewModel.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//
import SwiftUI

@Observable
class RouteViewModel {
    var state: RouteViewState = RouteViewState()
    private var dataManager: DataManaging

    init() {
        dataManager = DIContainer.shared.resolve()
    }

    func fetchRoutes() {
        state.routes = dataManager.fetchRoutes()
    }

    func saveRoute(_ route: Route) {
        dataManager.saveRoute(route)
        fetchRoutes()
    }

    var sortedRoutes: [Route] {
        state.routes.sorted { first, second in
            first.startDate < second.startDate
        }
    }
}
