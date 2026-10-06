//
//  RouteFormView.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 15.06.2026.
//

import MapKit
import SwiftUI

// Shared screen used for creating a new route and editing an existing route.
// Shows an interactive map with selected spots and presents the form in a sheet.
struct RouteFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var viewModel: RouteFormViewModel
    @State private var isFormPresented = false
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var isDeleteConfirmationPresented: Bool = false
    
    private let onDelete: (() -> Void)?

    init(viewModel: RouteFormViewModel, onDelete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDelete = onDelete
    }

    var body: some View {
        mapView
            .onAppear {
                viewModel.fetchAvailableSpots()
                isFormPresented = true
            }
            .onChange(of: viewModel.state.selectedSpots) { oldValue, newValue in
                updateMapCamera(for: newValue)
            }
            .sheet(isPresented: $isFormPresented) {
                formSheet
                    .presentationBackgroundInteraction(.enabled)
            }
    }

    // MARK: - Map View

    private var mapView: some View {
        Map(position: $mapCameraPosition) {
            // Numbered annotations for selected spots
            ForEach(Array(viewModel.state.selectedSpots.enumerated()), id: \.element.id) { index, spot in
                Annotation(spot.name, coordinate: spot.coordinate) {
                    ZStack {
                        Circle()
                            .fill(.blue)
                            .frame(width: 32, height: 32)
                            .shadow(radius: 3)
                        
                        Text("\(index + 1)")
                            .foregroundStyle(.white)
                            .font(.system(size: 14, weight: .bold))
                    }
                }
            }
            
            // Route polyline connecting spots in order
            if viewModel.state.selectedSpots.count > 1 {
                MapPolyline(coordinates: viewModel.state.selectedSpots.map { $0.coordinate })
                    .stroke(.blue, lineWidth: 3)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .ignoresSafeArea()
    }

    // MARK: - Form Sheet

    private var formSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    TextField("Route name*", text: $viewModel.state.name)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 9))

                    TextField("Number of spots*", text: $viewModel.state.desiredSpotCount)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 9))

                    dateSection
                    selectedSpotSection

                    TextField("Add note...", text: $viewModel.state.note, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $viewModel.state.isSpotPickerPresented) {
                spotPickerView
            }
            .toolbar {
                if viewModel.isEditing, onDelete != nil {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Delete Route", role: .destructive) {
                            isDeleteConfirmationPresented = true
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled()
            .confirmationDialog(
                "Photoshoot limit reached",
                isPresented: .constant(viewModel.state.limitExceededInfo != nil),
                titleVisibility: .visible
            ) {
                if let info = viewModel.state.limitExceededInfo {
                    // Option to increase spot count (only for totalSpots limit)
                    if case .totalSpots = info.limitType {
                        Button("Increase to \(viewModel.state.selectedSpots.count + 1) spots") {
                            viewModel.increaseSpotCountAndAdd(info.candidateSpot)
                            viewModel.state.limitExceededInfo = nil
                        }
                    }
                    
                    ForEach(viewModel.state.selectedSpots) { spot in
                        Button("Replace \"\(spot.name)\"") {
                            viewModel.replaceSpot(spot, with: info.candidateSpot)
                            viewModel.state.limitExceededInfo = nil
                        }
                    }
                }

                Button("Cancel", role: .cancel) {
                    viewModel.state.limitExceededInfo = nil
                }
            } message: {
                if let info = viewModel.state.limitExceededInfo {
                    Text(info.limitType.message)
                }
            }
            .confirmationDialog(
                "Remove spot from route?",
                isPresented: .constant(viewModel.state.spotToRemove != nil),
                titleVisibility: .visible
            ) {
                if let spot = viewModel.state.spotToRemove {
                    Button("Decrease to \(max(1, (Int(viewModel.state.desiredSpotCount) ?? viewModel.state.selectedSpots.count) - 1)) spots") {
                        viewModel.removeSpotAndDecrease(spot)
                        viewModel.state.spotToRemove = nil
                    }
                    
                    Button("Keep \(viewModel.state.desiredSpotCount) spots") {
                        viewModel.removeSpot(spot)
                        viewModel.state.spotToRemove = nil
                    }
                }

                Button("Cancel", role: .cancel) {
                    viewModel.state.spotToRemove = nil
                }
            } message: {
                Text("Would you like to decrease the number of desired spots?")
            }
            .alert(
                "Could not save route",
                isPresented: .constant(viewModel.state.errorMessage != nil)
            ) {
                Button("OK") {
                    viewModel.state.errorMessage = nil
                }
            } message: {
                Text(viewModel.state.errorMessage ?? "")
            }
            .alert(
                "Delete this route?",
                isPresented: $isDeleteConfirmationPresented
            ) {
                Button("Cancel", role: .cancel) {}

                Button("Delete Route", role: .destructive) {
                    onDelete?()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    // MARK: - Form Sections

    private var dateSection: some View {
        VStack(spacing: 0) {
            DatePicker("Start", selection: $viewModel.state.startDate)
                .padding(12)

            Divider()

            DatePicker("End", selection: $viewModel.state.endDate, in: viewModel.state.startDate...)
                .padding(12)
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private var selectedSpotSection: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.state.selectedSpots) { spot in
                SelectedRouteSpotRow(
                    spot: spot,
                    onRemove: {
                        viewModel.initiateRemoveSpot(spot)
                    }
                )

                Divider()
            }

            Button {
                viewModel.state.isSpotPickerPresented = true
            } label: {
                Text("Add spot...")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    // MARK: - Spot Picker

    private var spotPickerView: some View {
        // Spot cards
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.state.availableSpots) { spot in
                    SpotPickerCard(spot: spot) {
                        handleSpotSelection(spot)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .navigationTitle("Add Spot")
        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .topBarLeading) {
//                Button {
//                    viewModel.state.isSpotPickerPresented = false
//                } label: {
//                    Image(systemName: "xmark")
//                        .font(.system(size: 16, weight: .semibold))
//                        .foregroundStyle(.secondary)
//                        .frame(width: 32, height: 32)
//                        .background(
//                            Circle()
//                                .fill(Color(.systemGray5))
//                        )
//                }
//            }
//        }
        .onAppear {
            print("📱 Spot picker appeared")
            print("📱 Available spots count: \(viewModel.state.availableSpots.count)")
        }
    }
    
    private func handleSpotSelection(_ spot: Spot) {
        let result = viewModel.attemptToAddSpot(spot)
        
        switch result {
        case .added:
            viewModel.state.isSpotPickerPresented = false
            
        case .duplicate:
            viewModel.state.isSpotPickerPresented = false
            
        case .limitReached(let info):
            viewModel.state.isSpotPickerPresented = false
            viewModel.state.limitExceededInfo = info
        }
    }

    // MARK: - Map Camera Control

    private func updateMapCamera(for spots: [Spot]) {
        guard !spots.isEmpty else {
            mapCameraPosition = .automatic
            return
        }
        
        if spots.count == 1 {
            // Single spot - zoom to it
            let spot = spots[0]
            mapCameraPosition = .region(MKCoordinateRegion(
                center: spot.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        } else {
            // Multiple spots - fit all in view with padding
            let coordinates = spots.map { $0.coordinate }
            let rect = boundingMapRect(for: coordinates)
            mapCameraPosition = .rect(rect)
        }
    }

    private func boundingMapRect(for coordinates: [CLLocationCoordinate2D]) -> MKMapRect {
        guard !coordinates.isEmpty else {
            return MKMapRect.null
        }
        
        var mapRect = MKMapRect.null
        
        for coordinate in coordinates {
            let point = MKMapPoint(coordinate)
            let pointRect = MKMapRect(x: point.x, y: point.y, width: 0, height: 0)
            
            if mapRect.isNull {
                mapRect = pointRect
            } else {
                mapRect = mapRect.union(pointRect)
            }
        }
        
        // Add padding around the route
        let padding: Double = 10000 // meters
        return mapRect.insetBy(dx: -padding, dy: -padding)
    }
}
// MARK: - Spot Picker Card

private struct SpotPickerCard: View {
    let spot: Spot
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon, name, and address
                HStack(spacing: 12) {
                    // Spot icon with light condition color
                    ZStack {
                        Circle()
                            .fill(spot.lightConditions.first?.color ?? .gray)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: spot.lightConditions.first?.iconName ?? "photo")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(spot.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text(spot.address.formatted)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                
                // Photo
                if let photo = spot.photos.first,
                   let uiImage = UIImage(data: photo.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .clipped()
                } else {
                    // Placeholder when no photo
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 200)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

