//
//  CalendarView.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 15.06.2026.
//

import SwiftUI

// Month overview that marks days containing saved ShootBuddy routes.
struct CalendarView: View {
    @State private var viewModel: CalendarViewModel

    init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthHeader
                weekdayHeader
                monthGrid
                Spacer()
            }
            .padding(.horizontal)
            //.navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.fetchRoutes()
            }
            .navigationDestination(for: CalendarDay.self) { day in
                CalendarDayView(date: day.date, viewModel: viewModel)
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                viewModel.moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(viewModel.state.displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.title2.bold())

            Spacer()

            Button {
                viewModel.moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.vertical, 18)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 8)
    }

    private var monthGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
            spacing: 8
        ) {
            ForEach(Array(viewModel.daysInDisplayedMonth().enumerated()), id: \.offset) { _, date in
                if let date {
                    NavigationLink(value: CalendarDay(date: date)) {
                        dayCell(date)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(height: 58)
                }
            }
        }
    }

    // Highlights today and displays a dot when at least one route starts that day.
    private func dayCell(_ date: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(date)

        return VStack(spacing: 5) {
            Text(date.formatted(.dateTime.day()))
                .font(.body.weight(isToday ? .bold : .regular))
                .foregroundStyle(isToday ? .white : .primary)
                .frame(width: 34, height: 34)
                .background(isToday ? Color.blue : Color.clear, in: Circle())

            Circle()
                .fill(viewModel.hasRoutes(on: date) ? Color.blue : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
    }
}

// Hashable navigation value used to open a selected day.
private struct CalendarDay: Hashable {
    let date: Date
}
