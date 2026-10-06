//
//  RouteRow.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//
import SwiftUI

struct RouteRow: View {
    let item: Route

    var body: some View {
        NavigationLink {
            RouteDetailView(viewModel: RouteDetailViewModel(route: item))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(formattedDate(item.actualStartTime))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)

                    Spacer()

                    Text(formattedTimeRange(start: item.actualStartTime, end: item.actualEndTime))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(.darkGray))

                    Text("\(item.locationCount) locations • \(item.totalDistanceText)")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray5))
            )
        }
        .buttonStyle(.plain)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formattedTimeRange(start: Date, end: Date) -> String {
        "\(formattedTime(start)) - \(formattedTime(end))"
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "H:mm"
        return formatter.string(from: date)
    }
}
