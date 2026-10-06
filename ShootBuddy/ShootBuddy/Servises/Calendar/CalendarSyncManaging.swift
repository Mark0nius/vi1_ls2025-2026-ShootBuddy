//
//  CalendarSyncManaging.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 15.06.2026.
//

import Foundation

// A writable calendar account exposed by EventKit.
struct ExternalCalendar: Identifiable, Hashable {
    let id: String
    let title: String
    let sourceTitle: String
    let colorHex: String
}

// The operations needed to export ShootBuddy routes to a system calendar.
protocol CalendarSyncManaging {
    func writableCalendars() async throws -> [ExternalCalendar]
    func sync(route: Route, to calendarID: String) async throws -> String
}
