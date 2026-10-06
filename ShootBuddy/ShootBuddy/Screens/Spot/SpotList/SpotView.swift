//
//  SpotView.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//
import SwiftUI

// Environment key for triggering spot list refresh
struct SpotListRefresh {
    let trigger: () -> Void
}

private struct SpotListRefreshKey: EnvironmentKey {
    static let defaultValue = SpotListRefresh(trigger: {})
}

extension EnvironmentValues {
    var spotListRefresh: SpotListRefresh {
        get { self[SpotListRefreshKey.self] }
        set { self[SpotListRefreshKey.self] = newValue }
    }
}

struct SpotView: View {
    @State private var viewModel: SpotViewModel
    @State private var isFilterPresented: Bool = false
    @State private var refreshTrigger: Bool = false

    init(viewModel: SpotViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                searchBar
                spotList
            }
            .navigationTitle("Spots")
            .onAppear {
                print("📍 SpotView appeared - fetching spots")
                viewModel.fetchSpots()
            }
            .onChange(of: refreshTrigger) { _, _ in
                print("🔄 Refresh trigger changed - fetching spots")
                viewModel.fetchSpots()
            }
            .sheet(isPresented: $isFilterPresented) {
                filterSheet
            }
        }
        .environment(\.spotListRefresh, SpotListRefresh(trigger: {
            print("🎯 spotListRefresh.trigger() called")
            refreshTrigger.toggle()
        }))
    }

    // MARK: Search + filter

    private var searchBar: some View {
        @Bindable var viewModel = viewModel

        return HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search...", text: $viewModel.state.searchText)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )

            Button {
                isFilterPresented = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(.systemGray5)))
            }
        }
        .padding(.horizontal)
    }

    // MARK: Spot list

    @ViewBuilder
    private var spotList: some View {
        if viewModel.filteredSpots.isEmpty {
            ContentUnavailableView(
                "No Spots",
                systemImage: "binoculars",
                description: Text("Saved photo spots will appear here.")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredSpots) { spot in
                        SpotRow(item: spot)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
            .id(viewModel.state.refreshID)  // Force re-render when refreshID changes
        }
    }

    // MARK: Light filter (the "Pin filter" sheet)

    private var filterSheet: some View {
        NavigationStack {
            List(LightType.allCases) { light in
                Button {
                    viewModel.toggleFilter(light)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: light.iconName)
                            .foregroundStyle(light.color)
                            .frame(width: 28)

                        Text(light.name)
                            .foregroundStyle(.primary)

                        Spacer()

                        if viewModel.state.selectedLightFilters.contains(light) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Pin filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isFilterPresented = false
                    }
                }
            }
        }
    }
}

