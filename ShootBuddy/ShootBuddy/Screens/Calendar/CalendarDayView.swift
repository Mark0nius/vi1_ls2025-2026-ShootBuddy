//
//  CalendarDayView.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 15.06.2026.
//

import SwiftUI

// Day agenda showing route time blocks and controls for calendar export.
struct CalendarDayView: View {
    @Environment(\.dismiss) private var dismiss

    let date: Date
    @Bindable var viewModel: CalendarViewModel

    private let hourHeight: CGFloat = 64

    var body: some View {
        VStack(spacing: 0) {
            weekHeader

            ScrollView {
                ZStack(alignment: .topLeading) {
                    hourGrid
                    routeBlocks
                    currentTimeIndicator
                }
                .frame(height: hourHeight * 24)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label(
                        date.formatted(.dateTime.month(.wide)),
                        systemImage: "chevron.left"
                    )
                }
            }
        }
        .overlay {
            if viewModel.state.isLoadingCalendars {
                ProgressView("Loading calendars...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(isPresented: $viewModel.state.isCalendarPickerPresented) {
            calendarPicker
        }
        .alert("Calendar", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.state.errorMessage ?? "Unknown error")
        }
        .alert("Export complete", isPresented: successAlertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.state.successMessage ?? "Route exported.")
        }
    }

    // Displays the selected day and the surrounding week above the hourly agenda.
    private var weekHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(daysInSelectedWeek, id: \.self) { weekDate in
                    VStack(spacing: 7) {
                        Text(weekDate.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(weekDate.formatted(.dateTime.day()))
                            .font(.body.weight(isSelectedDay(weekDate) ? .semibold : .regular))
                            .foregroundStyle(isSelectedDay(weekDate) ? .white : .primary)
                            .frame(width: 32, height: 32)
                            .background(
                                isSelectedDay(weekDate) ? Color.blue : Color.clear,
                                in: Circle()
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 10)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // Draws 24 horizontal hour rows behind route cards.
    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                HStack(alignment: .top, spacing: 8) {
                    Text(hourLabel(hour))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .trailing)

                    Rectangle()
                        .fill(Color(.separator))
                        .frame(maxWidth: .infinity)
                        .frame(height: 0.5)
                        .padding(.top, 6)
                }
                .frame(height: hourHeight, alignment: .top)
                .id(hour)
            }
        }
    }

    // Positions each route according to its start and end times.
    private var routeBlocks: some View {
        ForEach(viewModel.routes(on: date)) { route in
            Button {
                Task {
                    await viewModel.prepareCalendarPicker(for: route)
                }
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(route.name)
                        .font(.subheadline.bold())
                        .lineLimit(1)

                    Text(routeTime(route))
                        .font(.caption)

                    if route.calendarEventID != nil {
                        Label("Synced", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color.blue.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .frame(height: routeHeight(route), alignment: .top)
            .padding(.leading, 64)
            .padding(.trailing, 12)
            .offset(y: routeOffset(route))
        }
    }

    // Shows the current time only when the selected date is today.
    @ViewBuilder
    private var currentTimeIndicator: some View {
        if Calendar.current.isDateInToday(date) {
            let now = Date()

            HStack(spacing: 0) {
                Text(now.formatted(date: .omitted, time: .shortened))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 52, alignment: .trailing)

                Circle()
                    .fill(.blue)
                    .frame(width: 6, height: 6)

                Rectangle()
                    .fill(.blue)
                    .frame(height: 1)
            }
            .offset(y: timeOffset(now) - 5)
        }
    }

    // Lets the user choose iCloud, Google, Exchange, or another writable calendar.
    private var calendarPicker: some View {
        NavigationStack {
            List(viewModel.state.writableCalendars) { calendar in
                Button {
                    Task {
                        await viewModel.syncSelectedRoute(to: calendar)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: calendar.colorHex))
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading) {
                            Text(calendar.title)
                                .foregroundStyle(.primary)
                            Text(calendar.sourceTitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Choose Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.state.isCalendarPickerPresented = false
                    }
                }
            }
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.errorMessage != nil },
            set: { if !$0 { viewModel.state.errorMessage = nil } }
        )
    }

    private var successAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.successMessage != nil },
            set: { if !$0 { viewModel.state.successMessage = nil } }
        )
    }

    private func routeOffset(_ route: Route) -> CGFloat {
        timeOffset(route.actualStartTime)
    }

    private func routeHeight(_ route: Route) -> CGFloat {
        let minutes = max(route.actualEndTime.timeIntervalSince(route.actualStartTime) / 60, 30)
        return CGFloat(minutes / 60) * hourHeight
    }

    private func routeTime(_ route: Route) -> String {
        "\(route.actualStartTime.formatted(date: .omitted, time: .shortened)) - \(route.actualEndTime.formatted(date: .omitted, time: .shortened))"
    }

    private func hourLabel(_ hour: Int) -> String {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: date)?
            .formatted(date: .omitted, time: .shortened) ?? ""
    }

    private var daysInSelectedWeek: [Date] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: date) else {
            return []
        }

        return (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: interval.start)
        }
    }

    private func isSelectedDay(_ weekDate: Date) -> Bool {
        Calendar.current.isDate(weekDate, inSameDayAs: date)
    }

    private func timeOffset(_ time: Date) -> CGFloat {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let minutes = CGFloat((components.hour ?? 0) * 60 + (components.minute ?? 0))
        return minutes / 60 * hourHeight
    }
}

private extension Color {
    // Creates a SwiftUI color from the hexadecimal value supplied by EventKit.
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0x007AFF
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
