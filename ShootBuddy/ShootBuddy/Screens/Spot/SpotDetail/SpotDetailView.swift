//
//  SpotDetailView.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 15.06.2026.
//

import SwiftUI
import MapKit

struct SpotDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.spotListRefresh) private var spotListRefresh

    @State private var viewModel: SpotDetailViewModel
    @State private var photoIndex: Int = 0
    @State private var editingSpot: Spot?
    @State private var isAddToRoutePresented: Bool = false
    @State private var selectedRouteForNavigation: Route?

    init(viewModel: SpotDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header(spot: viewModel.state.spot)
                photoCarousel(spot: viewModel.state.spot)

                // MARK: marek edit
                card(title: "Light filters") {
                    VStack(alignment: .leading,spacing: 8) {
                        ForEach(viewModel.state.spot.lightConditions) { light in
                            
                                HStack(spacing: 6) {
                                    Image(systemName: light.iconName)
                                        .foregroundStyle(light.color)
                                        .frame(width: 28, alignment: .center) //icon centering
                                    Text(light.name)
                                }
                            
                        }
                    }
                } //edit-end
            
                
                if let note = viewModel.state.spot.note, !note.isEmpty {
                    card(title: "Note") {
                        Text(note)
                    }
                }

                //jen dal obrazek před text
                card(title: "Spot weather report") {
                    HStack(spacing: 8) {
                        if let weather = viewModel.state.weather {
                             Image(systemName: weather.iconName)
                                 .foregroundStyle(.secondary)
                         }
                        
                        Text(viewModel.state.weather?.name ?? "Loading…")

                       /* if let weather = viewModel.state.weather {
                            Image(systemName: weather.iconName)
                                .foregroundStyle(.secondary)
                        } */
                    }
                }

                mapSection(spot: viewModel.state.spot)
            }
            .padding(.vertical)
        }
        .id(viewModel.state.refreshID)  // Force re-render when refreshID changes
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Spot Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingSpot = viewModel.state.spot
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }

            ToolbarItem(placement: .bottomBar) {
                Button {
                    isAddToRoutePresented = true
                } label: {
                    Text("Add to Route")
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
            }
        }
        // .sheet(item:) builds the sheet from the CURRENT spot every time, and
        // SpotEditSheet owns its edit view model — so the instance you type into
        // is always the instance Save reads. (Fixes the lost-first-edit bug.)
        .sheet(item: $editingSpot) { spotToEdit in
            SpotEditSheet(
                spot: spotToEdit,
                onSaved: {
                    viewModel.refreshSpot()
                    spotListRefresh.trigger()  // Also refresh the list
                },
                onDeleted: { dismiss() }
            )
        }
        .sheet(isPresented: $isAddToRoutePresented) {
            AddSpotToRouteView(spot: viewModel.state.spot) { selectedRoute in
                addSpotToRoute(selectedRoute)
            }
        }
        .navigationDestination(item: $selectedRouteForNavigation) { route in
            RouteDetailView(viewModel: RouteDetailViewModel(route: route))
        }
        .onAppear {
            viewModel.fetchWeatherData()
        }
    }
    
    // MARK: - Actions
    
    private func addSpotToRoute(_ route: Route) {
        Task {
            let addViewModel = AddSpotToRouteViewModel(spot: viewModel.state.spot)
            await addViewModel.addSpotToRoute(route)
            
            print("✅ Added '\(viewModel.state.spot.name)' to route '\(route.name)'")
            
            // Fetch the updated route from the database before navigating
            let dataManager: DataManaging = DIContainer.shared.resolve()
            let allRoutes = dataManager.fetchRoutes()
            
            if let updatedRoute = allRoutes.first(where: { $0.id == route.id }) {
                // Navigate to the route detail with the updated route
                selectedRouteForNavigation = updatedRoute
            } else {
                print("⚠️ Could not find updated route for navigation")
            }
        }
    }

    // MARK: - Header

    private func header(spot: Spot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(spot.name)
                .font(.title)
                .fontWeight(.bold)

            Text(spot.address.formatted)
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    // MARK: - Photo carousel

    @ViewBuilder
    private func photoCarousel(spot: Spot) -> some View {
        let photos = spot.photos

        ZStack(alignment: .bottom) {
            if photos.isEmpty {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.tertiarySystemFill))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            } else {
                TabView(selection: $photoIndex) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        photoImage(photo)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                if photos.count > 1 {
                    pageControl(count: photos.count)
                        .padding(.bottom, 8)
                }
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    @ViewBuilder
    private func photoImage(_ photo: Photo) -> some View {
        if let uiImage = UIImage(data: photo.imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            Color(.tertiarySystemFill)
        }
    }

    private func pageControl(count: Int) -> some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == photoIndex ? Color.blue : Color.white.opacity(0.7))
                    .frame(width: 7, height: 7)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .animation(.easeInOut, value: photoIndex)
    }

    // MARK: - Map

    private func mapSection(spot: Spot) -> some View {
        Map(
            initialPosition: .region(
                MKCoordinateRegion(
                    center: spot.coordinate,
                    latitudinalMeters: 800,
                    longitudinalMeters: 800
                )
            )
        ) {
            Marker(spot.name, coordinate: spot.coordinate)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .allowsHitTesting(false)
        .padding(.horizontal)
    }

    // MARK: - Card helper

    private func card<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Edit sheet

/// Owns its own `SpotAddViewModel` (created from the spot), so the instance the
/// user edits is always the instance `saveSpot()` reads.
private struct SpotEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: SpotAddViewModel
    @State private var isDeleteConfirmationPresented: Bool = false

    private let onSaved: () -> Void
    private let onDeleted: () -> Void

    init(spot: Spot, onSaved: @escaping () -> Void, onDeleted: @escaping () -> Void) {
        self.viewModel = SpotAddViewModel(spot: spot)
        self.onSaved = onSaved
        self.onDeleted = onDeleted
    }

    var body: some View {
        NavigationStack {
            SpotAddView(viewModel: viewModel)
                .navigationTitle(viewModel.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close", role: .cancel) {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            Task {
                                if await viewModel.saveSpot() {
                                    onSaved()
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!viewModel.canSave)
                    }

                    if viewModel.isEditing {
                        ToolbarItem(placement: .bottomBar) {
                            Button("Delete Spot", role: .destructive) {
                                isDeleteConfirmationPresented = true
                            }
                        }
                    }
                }
                .alert(
                    "Delete this spot?",
                    isPresented: $isDeleteConfirmationPresented
                ) {
                    Button("Cancel", role: .cancel) {}

                    Button("Delete Spot", role: .destructive) {
                        if viewModel.deleteSpot() {
                            dismiss()
                            onDeleted()
                        }
                    }
                } message: {
                    Text("This action cannot be undone.")
                }
        }
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    NavigationStack {
        SpotDetailView(
            viewModel: SpotDetailViewModel(
                spot: Spot(
                    name: "Silver Hill",
                    address: Address(
                        street: "Malinovského náměstí",
                        houseNumber: "1984",
                        orientationalNumber: "16",
                        city: "Brno"
                    ),
                    coordinate: CLLocationCoordinate2D(latitude: 49.195, longitude: 16.606),
                    lightConditions: [.goldenHour],
                    photos: [],
                    note: "Possible café rooftop nearby for overhead frames"
                )
            )
        )
    }
}
