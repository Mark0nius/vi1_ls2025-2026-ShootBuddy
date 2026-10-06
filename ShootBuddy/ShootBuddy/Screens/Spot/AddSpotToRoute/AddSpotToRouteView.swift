//
//  AddSpotToRouteView.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 17.06.2026.
//

import SwiftUI
import CoreLocation

struct AddSpotToRouteView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onRouteSelected: (Route) -> Void
    
    @State private var viewModel: AddSpotToRouteViewModel
    
    init(spot: Spot, onRouteSelected: @escaping (Route) -> Void) {
        self.onRouteSelected = onRouteSelected
        self.viewModel = AddSpotToRouteViewModel(spot: spot)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                if viewModel.state.routes.isEmpty {
                    emptyState
                } else {
                    routesList
                }
                
                // Show loading overlay when regenerating route
                if viewModel.state.isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("Add to Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                    }
                }
            }
            .onAppear {
                viewModel.loadRoutes()
            }
        }
    }
    
    // MARK: - Routes List
    
    private var routesList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.state.routes) { route in
                    RouteCard(route: route) {
                        handleRouteSelection(route)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Routes Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create a route first to add this spot")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                
                Text("Optimizing route...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray))
            )
        }
    }
    
    // MARK: - Actions
    
    private func handleRouteSelection(_ route: Route) {
        onRouteSelected(route)
        dismiss()
    }
}

// MARK: - Route Card

private struct RouteCard: View {
    let route: Route
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(formattedDate(route.startDate))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                    
                    Spacer()
                    
                    Text(formattedTimeRange(start: route.startDate, end: route.endDate))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(route.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(.darkGray))
                    
                    Text("\(route.locationCount) locations • \(route.totalDistanceText)")
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

// MARK: - Preview

#Preview {
    AddSpotToRouteView(
        spot: Spot(
            name: "Silver Hill",
            address: Address(
                street: "Malinovského náměstí",
                houseNumber: "1984",
                orientationalNumber: "16",
                city: "Brno"
            ),
            coordinate: .init(latitude: 49.195, longitude: 16.606),
            lightConditions: [.goldenHour],
            photos: [],
            note: nil
        ),
        onRouteSelected: { _ in }
    )
}
