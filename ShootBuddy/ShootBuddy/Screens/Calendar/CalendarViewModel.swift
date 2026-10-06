//
//  CalendarViewModel.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 15.06.2026.
//

import SwiftUI

// Provides calendar dates, filters routes by selected day,
@Observable
final class CalendarViewModel {
    var state = CalendarViewState()

    private let dataManager: DataManaging
    private let calendarManager: CalendarSyncManaging
    private let calendar = Calendar.current

    init(
        dataManager: DataManaging = DIContainer.shared.resolve(),
        calendarManager: CalendarSyncManaging = AppleCalendarManager()
    ) {
        self.dataManager = dataManager
        self.calendarManager = calendarManager
    }

    // Reloads routes so changes made elsewhere in the app appear in the calendar.
    func fetchRoutes() {
        state.routes = dataManager.fetchRoutes()
    }

    // Moves the month grid backward or forward by one month.
    func moveMonth(by value: Int) {
        guard let month = calendar.date(byAdding: .month, value: value, to: state.displayedMonth) else {
            return
        }
        state.displayedMonth = month
    }

    // Returns the leading empty cells and  days needed by a month grid.
    func daysInDisplayedMonth() -> [Date?] {
        guard
            let interval = calendar.dateInterval(of: .month, for: state.displayedMonth),
            let dayRange = calendar.range(of: .day, in: .month, for: interval.start)
        else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leadingEmptyCells = (firstWeekday - calendar.firstWeekday + 7) % 7
        let days = dayRange.compactMap {
            calendar.date(byAdding: .day, value: $0 - 1, to: interval.start)
        }

        return Array(repeating: nil, count: leadingEmptyCells) + days.map(Optional.some)
    }

    // Filters saved routes whose start date falls on the requested calendar day.
    func routes(on date: Date) -> [Route] {
        state.routes
            .filter { calendar.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
    }

    func hasRoutes(on date: Date) -> Bool {
        !routes(on: date).isEmpty
    }

    // Orders weekday symbols so the header matches the user's regional settings.
    var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let startIndex = calendar.firstWeekday - 1
        return Array(symbols[startIndex...]) + Array(symbols[..<startIndex])
    }

    // Opens the destination calendar picker after EventKit access is granted.
    func prepareCalendarPicker(for route: Route) async {
        state.selectedRoute = route
        state.isLoadingCalendars = true
        state.errorMessage = nil

        do {
            state.writableCalendars = try await calendarManager.writableCalendars()
            if state.writableCalendars.isEmpty {
                state.errorMessage = "No writable calendars are available on this device."
            } else {
                state.isCalendarPickerPresented = true
            }
        } catch {
            state.errorMessage = error.localizedDescription
        }

        state.isLoadingCalendars = false
    }

    // Exports the selected route and persists its EventKit identifier for future updates.
    func syncSelectedRoute(to externalCalendar: ExternalCalendar) async {
        guard var route = state.selectedRoute else { return }

        do {
            route.calendarEventID = try await calendarManager.sync(
                route: route,
                to: externalCalendar.id
            )
            dataManager.saveRoute(route)
            replaceRoute(route)
            state.isCalendarPickerPresented = false
            state.successMessage = "Route saved to \(externalCalendar.title)."
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    // Replaces the in-memory route after its calendar identifier changes.
    private func replaceRoute(_ route: Route) {
        guard let index = state.routes.firstIndex(where: { $0.id == route.id }) else { return }
        state.routes[index] = route
        state.selectedRoute = route
    }
}
