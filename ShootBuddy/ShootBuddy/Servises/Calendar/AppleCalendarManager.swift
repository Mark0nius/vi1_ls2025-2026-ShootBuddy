//
//  AppleCalendarManager.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 15.06.2026.
//

import EventKit
import UIKit

// Errors that can occur while requesting access or saving an EventKit event.
enum AppleCalendarError: LocalizedError {
    case accessDenied
    case calendarNotFound
    case eventIdentifierMissing

    var errorDescription: String? {
        switch self {
            case .accessDenied:
                return "Calendar access was not granted. You can enable it in Settings."
            case .calendarNotFound:
                return "The selected calendar is no longer available."
            case .eventIdentifierMissing:
                return "The calendar event was saved without an identifier."
        }
    }
}

// Uses EventKit to create or update route events in any writable system calendar.
final class AppleCalendarManager: CalendarSyncManaging {
    private let eventStore = EKEventStore()

    // Requests full event access and returns calendars that accept new events.
    func writableCalendars() async throws -> [ExternalCalendar] {
        try await requestAccess()

        return eventStore.calendars(for: .event)
            .filter(\.allowsContentModifications)
            .map { calendar in
                ExternalCalendar(
                    id: calendar.calendarIdentifier,
                    title: calendar.title,
                    sourceTitle: calendar.source.title,
                    colorHex: UIColor(cgColor: calendar.cgColor).hexString
                )
            }
            .sorted {
                if $0.sourceTitle == $1.sourceTitle {
                    return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
                return $0.sourceTitle.localizedCaseInsensitiveCompare($1.sourceTitle) == .orderedAscending
            }
    }

    // Updates the previously exported event when possible, otherwise creates a new one.
    func sync(route: Route, to calendarID: String) async throws -> String {
        try await requestAccess()

        guard let calendar = eventStore.calendar(withIdentifier: calendarID),
              calendar.allowsContentModifications else {
            throw AppleCalendarError.calendarNotFound
        }

        let event = route.calendarEventID
            .flatMap(eventStore.event(withIdentifier:))
            ?? EKEvent(eventStore: eventStore)

        event.calendar = calendar
        event.title = route.name
        event.startDate = route.actualStartTime
        event.endDate = route.actualEndTime
        event.notes = eventNotes(for: route)

        if let firstStop = route.stops.first {
            event.location = firstStop.spot.address.formatted
        }

        try eventStore.save(event, span: .thisEvent, commit: true)

        guard let eventIdentifier = event.eventIdentifier else {
            throw AppleCalendarError.eventIdentifierMissing
        }
        return eventIdentifier
    }

    // Requests the modern full-access permission required for creating events.
    private func requestAccess() async throws {
        let granted = try await eventStore.requestFullAccessToEvents()
        guard granted else {
            throw AppleCalendarError.accessDenied
        }
    }

    // Produces a readable stop list that appears in the exported event notes.
    private func eventNotes(for route: Route) -> String {
        let stopLines = route.stops.enumerated().map { index, stop in
            let time = stop.arrivalTime.formatted(date: .omitted, time: .shortened)
            return "\(index + 1). \(time) - \(stop.spot.name)"
        }

        return ([route.note].compactMap { $0 } + stopLines).joined(separator: "\n")
    }
}

private extension UIColor {
    // Converts an EventKit calendar color into a value SwiftUI can reconstruct.
    var hexString: String {
        guard let components = cgColor.components else { return "#007AFF" }
        let red = components[0]
        let green = components.count > 2 ? components[1] : components[0]
        let blue = components.count > 2 ? components[2] : components[0]
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}
