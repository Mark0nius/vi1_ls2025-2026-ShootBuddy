//
//  CalendarViewState.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 15.06.2026.
//

import SwiftUI

// Mutable state shared by the month view, day view, and calendar picker.
@Observable
final class CalendarViewState {
    var routes: [Route] = []
    var displayedMonth = Date()
    var selectedDate = Date()
    var selectedRoute: Route?
    var writableCalendars: [ExternalCalendar] = []
    var isCalendarPickerPresented = false
    var isLoadingCalendars = false
    var errorMessage: String?
    var successMessage: String?
}
