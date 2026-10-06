//
//  MapView.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State private var viewModel: MapViewModel

    init(viewModel: MapViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        MapReader { mapProxy in
            Map(position: $viewModel.state.cameraPosition) {
                UserAnnotation()

                ForEach(viewModel.state.spots) { spot in
                    Annotation("", coordinate: spot.coordinate) {
                        spotAnnotation(spot)
                            .onTapGesture {
                                viewModel.selectSpot(spot)
                            }
                    }
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        viewModel.updateLongPressLocation(value.location)
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.6)
                    .onEnded { _ in
                        guard
                            let location = viewModel.state.longPressLocation,
                            let coordinate = mapProxy.convert(location, from: .local)
                        else {
                            return
                        }

                        viewModel.startNewSpot(at: coordinate)
                    }
            )
            .mapStyle(viewModel.state.selectedMapStyle.mapStyle)
            .ignoresSafeArea()
            .overlay(alignment: .bottomTrailing) {
                mapControls
                    .padding(.trailing, 16)
                    .padding(.bottom, 25)
            }
            .onAppear {
                viewModel.fetchSpots()
                viewModel.moveCameraToUserLocation()
            }
            .sheet(item: $viewModel.state.selectedSpot, onDismiss: {
                viewModel.fetchSpots()
            }) { spot in
                spotDetailSheet(spot)
            }
            .sheet(item: $viewModel.state.newSpotDraft, onDismiss: {
                viewModel.clearNewSpotDraft()
                viewModel.fetchSpots()
            }) { draft in
                newSpotSheet(coordinate: draft.coordinate)
            }
        }
    }

    // MARK: - New spot sheet

    // Builds the form for creating a new spot from the long-pressed map coordinate.
    private func newSpotSheet(coordinate: CLLocationCoordinate2D) -> some View {
        NewMapSpotSheet(
            coordinate: coordinate,
            onSaved: {
                viewModel.clearNewSpotDraft()
                viewModel.fetchSpots()
            },
            onCancelled: {
                viewModel.clearNewSpotDraft()
            }
        )
    }

    // MARK: - Apple Maps-like connected controls

    private var mapControls: some View {
        VStack(spacing: 0) {
            mapStyleMenu

            Divider()
                .frame(width: 28)

            userLocationButton
        }
        .frame(width: 46)
        .glassControlBackground()
    }

    private var mapStyleMenu: some View {
        Menu {
            ForEach(ShootBuddyMapStyle.allCases) { mapStyle in
                Button {
                    viewModel.changeMapStyle(mapStyle)
                } label: {
                    Label(mapStyle.title, systemImage: mapStyle.iconName)
                }
            }
        } label: {
            Image(systemName: viewModel.state.selectedMapStyle.iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.75))
                .frame(width: 46, height: 46)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var userLocationButton: some View {
        Button {
            withAnimation(.smooth) {
                viewModel.moveCameraToUserLocation()
            }
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.75))
                .frame(width: 46, height: 46)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Spot annotation

    private func spotAnnotation(_ spot: Spot) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.9))
                    .frame(width: 42, height: 42)

                Circle()
                    .fill(Color.white)
                    .frame(width: 28, height: 28)

                Image(systemName: "binoculars.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.blue)
            }

            Triangle()
                .fill(Color.blue.opacity(0.9))
                .frame(width: 12, height: 8)
                .rotationEffect(.degrees(180))
                .offset(y: -1)
        }
        .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
    }

    // MARK: - Spot detail sheet

    private func spotDetailSheet(_ spot: Spot) -> some View {
        NavigationStack {
            SpotDetailView(viewModel: SpotDetailViewModel(spot: spot))
        }
//        .presentationDetents([.fraction(0.3), .medium])
    }
}

// MARK: - Glass control background

private extension View {
    @ViewBuilder
    func glassControlBackground() -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 23))
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 23))
                .overlay {
                    RoundedRectangle(cornerRadius: 23)
                        .stroke(.white.opacity(0.25), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.16), radius: 10, y: 4)
        }
    }
}

// MARK: - New map spot sheet

private struct NewMapSpotSheet: View {
    @State private var viewModel: SpotAddViewModel

    let onSaved: () -> Void
    let onCancelled: () -> Void

    init(
        coordinate: CLLocationCoordinate2D,
        onSaved: @escaping () -> Void,
        onCancelled: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: SpotAddViewModel(coordinates: coordinate))
        self.onSaved = onSaved
        self.onCancelled = onCancelled
    }

    // Shows the add spot form and pre-fills address fields from the pinned coordinate.
    var body: some View {
        NavigationStack {
            SpotAddView(viewModel: viewModel)
                .navigationTitle(viewModel.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close", role: .cancel) {
                            onCancelled()
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            Task {
                                let saved = await viewModel.saveSpot()

                                if saved {
                                    onSaved()
                                }
                            }
                        }
                        .disabled(!viewModel.canSave)
                    }
                }
                .task {
                    await viewModel.fillAddressFromPinnedCoordinate()
                }
        }
    }
}

// MARK: - Triangle shape for map pin

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

#Preview {
    MapView(viewModel: MapViewModel())
}
