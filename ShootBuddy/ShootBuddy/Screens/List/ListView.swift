//
//  ListView.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 13.06.2026.
//

import SwiftUI

struct ListView: View {
    @State private var viewModel: ListViewModel
    @State private var addTarget: AddTarget?
    @State private var routeListRefreshTrigger = 0  // Increment to force refresh
    
    @State private var spotAddViewModel: SpotAddViewModel = SpotAddViewModel()
    @State private var showNewRouteForm: Bool = false

    init(viewModel: ListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            content
                .environment(\.routeListRefresh, RouteListRefresh(trigger: {
                    print("🔄 RouteListRefresh.trigger() called from NavigationStack level")
                    viewModel.routeViewModel.fetchRoutes()
                    DispatchQueue.main.async {
                        self.routeListRefreshTrigger += 1
                        print("🔄 Refresh trigger incremented to: \(self.routeListRefreshTrigger)")
                    }
                }))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Picker("", selection: $viewModel.state.mode) {
                            ForEach(ListMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 220)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        addMenu
                    }
                }
                .sheet(item: $addTarget) { target in
                    addSheet(for: target)
                }
                .fullScreenCover(isPresented: $showNewRouteForm) {
                    newRouteFormView()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state.mode {
            case .spots:
                SpotView(viewModel: viewModel.spotViewModel)
                    .onAppear {
                        viewModel.spotViewModel.fetchSpots()
                    }

            case .routes:
                RouteView(viewModel: viewModel.routeViewModel)
                    .id(routeListRefreshTrigger)  // Force refresh when trigger changes
                    .onAppear {
                        viewModel.routeViewModel.fetchRoutes()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .routeListNeedsRefresh)) { _ in
                        print("🔔 Received routeListNeedsRefresh notification")
                        viewModel.routeViewModel.fetchRoutes()
                        routeListRefreshTrigger += 1
                        print("🔄 Refresh trigger incremented to: \(routeListRefreshTrigger)")
                    }
        }
    }

    // MARK: - Add menu

    private var addMenu: some View {
        Menu {
            ForEach(AddTarget.allCases) { target in
                Button {
                    showAddDestination(for: target)
                } label: {
                    Label(target.title, systemImage: target.iconName)
                }
            }
        } label: {
            Image(systemName: "plus")
        }
    }

    private func showAddDestination(for target: AddTarget) {
        switch target {
            case .spot:
                addTarget = .spot

            case .route:
                showNewRouteForm = true
        }
    }

    // MARK: - Route Form

    @ViewBuilder
    private func newRouteFormView() -> some View {
        RouteFormSheet(
            onSaved: {
                print("📝 New route saved, refreshing list")
                self.viewModel.routeViewModel.fetchRoutes()
                self.routeListRefreshTrigger += 1
                showNewRouteForm = false
            },
            onCancelled: {
                showNewRouteForm = false
            }
        )
    }

    // MARK: - Sheets

    @ViewBuilder
    private func addSheet(for target: AddTarget) -> some View {
        switch target {
            case .spot:
                showAddSpot()

            case .route:
                // Routes now use navigation destination instead of sheet
                EmptyView()
        }
    }

    private func showAddSpot() -> some View {
        return NavigationStack {
            SpotAddView(viewModel: spotAddViewModel)
                .navigationTitle(spotAddViewModel.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close", role: .cancel) {
                            addTarget = nil
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            Task {
                                let saved = await spotAddViewModel.saveSpot()

                                if saved {
                                    addTarget = nil
                                    viewModel.spotViewModel.fetchSpots()
                                    spotAddViewModel = SpotAddViewModel()
                                }
                            }
                        }
                        .disabled(!spotAddViewModel.canSave)
                    }
                }
        }
    }
}

// MARK: - Route Form Sheet Wrapper

/// Wrapper view that owns the RouteFormViewModel for creating new routes
private struct RouteFormSheet: View {
    @State private var viewModel = RouteFormViewModel()
    
    let onSaved: () -> Void
    let onCancelled: () -> Void
    
    var body: some View {
        NavigationStack {
            RouteFormView(viewModel: viewModel, onDelete: nil)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") {
                            onCancelled()
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            Task {
                                let saved = await viewModel.saveRoute()
                                if saved {
                                    onSaved()
                                }
                            }
                        }
                        .disabled(!viewModel.canSave)
                    }
                }
        }
    }
}

// MARK: - Route List Refresh Environment

/// A mechanism to trigger route list refresh from child views (like RouteDetailView)
struct RouteListRefresh {
    var trigger: () -> Void
}
/// Environment key for route list refresh
struct RouteListRefreshKey: EnvironmentKey {
    static let defaultValue = RouteListRefresh(trigger: {
        print("⚠️ Default RouteListRefresh trigger called - environment not provided")
    })
}

extension EnvironmentValues {
    var routeListRefresh: RouteListRefresh {
        get { self[RouteListRefreshKey.self] }
        set { self[RouteListRefreshKey.self] = newValue }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let routeListNeedsRefresh = Notification.Name("routeListNeedsRefresh")
}

