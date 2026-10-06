//
//  RouteDetailView.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 16.06.2026.
//

import SwiftUI
import MapKit

struct RouteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.routeListRefresh) private var routeListRefresh
    
    @State private var viewModel: RouteDetailViewModel
    @State private var editingRoute: Route?
    @State private var selectedSpot: Spot?
    
    // Computed property that captures current environment value
    private var refreshTrigger: () -> Void {
        let trigger = routeListRefresh.trigger
        print("🧪 refreshTrigger computed property accessed, will use: \(type(of: trigger))")
        return trigger
    }

    init(viewModel: RouteDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let _ = print("🧪 RouteDetailView.body accessed, routeListRefresh is: \(routeListRefresh)")
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                mapSection
                timelineSection
                
                if let note = viewModel.state.route.note, !note.isEmpty {
                    noteSection(note: note)
                }
            }
            .padding(.vertical)
        }
        .id(viewModel.state.refreshID)  // Force re-render when refreshID changes
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Route Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingRoute = viewModel.state.route
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(.blue)
                }
            }
        }
        .fullScreenCover(item: $editingRoute) { routeToEdit in
            let _ = print("🧪 fullScreenCover creating RouteEditSheet")
            RouteEditSheet(
                route: routeToEdit,
                onSaved: {
                    print("✅ RouteEditSheet onSaved called")
                    viewModel.refreshRoute()
                    // Post notification instead of using environment
                    NotificationCenter.default.post(name: .routeListNeedsRefresh, object: nil)
                },
                onDeleted: { 
                    dismiss() 
                }
            )
        }
        .navigationDestination(item: $selectedSpot) { spot in
            SpotDetailView(viewModel: SpotDetailViewModel(spot: spot))
        }
    }

    // MARK: - Header
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.state.route.name)
                .font(.system(size: 28, weight: .bold))
            
            HStack(spacing: 4) {
                Text("\(viewModel.state.route.locationCount) locations")
                    .font(.system(size: 17))
                    .foregroundStyle(.blue)
                
                Text("•")
                    .foregroundStyle(.blue)
                
                Text(viewModel.state.route.totalDistanceText)
                    .font(.system(size: 17))
                    .foregroundStyle(.blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    // MARK: - Map Section
    
    private var mapSection: some View {
        let route = viewModel.state.route
        let coordinates = viewModel.state.coordinates
        
        return Map(initialPosition: viewModel.mapCameraPosition) {
            // Add markers for each stop
            ForEach(route.stops) { stop in
                Marker(stop.spot.name, coordinate: stop.spot.coordinate)
                    .tint(stop.assignedLight.color)
            }
            
            // Add polyline connecting the stops
            if coordinates.count > 1 {
                MapPolyline(coordinates: coordinates)
                    .stroke(.blue.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [10, 5]))
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .allowsHitTesting(false)
        .padding(.horizontal)
    }
    
    // MARK: - Timeline Section
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel.state.indexedStops, id: \.stop.id) { item in
                TimelineStopRow(
                    stop: item.stop,
                    isFirst: item.isFirst,
                    isLast: item.isLast,
                    viewModel: viewModel,
                    onTap: { selectedSpot = item.stop.spot }
                )
                
                // Show travel time indicator between stops
                if item.index < viewModel.state.route.stops.count - 1 {
                    let nextStop = viewModel.state.route.stops[item.index + 1]
                    if nextStop.travelTimeFromPrevious > 0 {
                        TravelTimeIndicator(
                            travelTime: nextStop.travelTimeFromPrevious,
                            transportMode: viewModel.state.route.transportMode,
                            viewModel: viewModel
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Note Section
    
    private func noteSection(note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note")
                .font(.headline)
            
            Text(note)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .padding(.horizontal)
    }
}
