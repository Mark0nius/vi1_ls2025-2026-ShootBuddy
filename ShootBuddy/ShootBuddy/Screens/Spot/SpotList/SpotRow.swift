//
//  SpotRow.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//
import SwiftUI

struct SpotRow: View {
    let item: Spot

    var body: some View {
        NavigationLink {
            SpotDetailView(viewModel: SpotDetailViewModel(spot: item))
        } label: {
            HStack(spacing: 14) {
                lightBadge

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(item.address.formatted)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }

    /// Circular badge showing the spot's (first) light condition.
    @ViewBuilder
    private var lightBadge: some View {
        let light = item.lightConditions.first
        Image(systemName: light?.iconName ?? "mappin.circle.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(Circle().fill(light?.color ?? .gray))
    }
}

