//
//  RouteView.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//
import SwiftUI

struct RouteView: View {
    @State private var viewModel: RouteViewModel

    init(viewModel: RouteViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        routeList
            .navigationTitle("Routes")
            .onAppear {
                viewModel.fetchRoutes()
            }
    }

    @ViewBuilder
    private var routeList: some View {
        if viewModel.sortedRoutes.isEmpty {
            ContentUnavailableView(
                "No Routes",
                systemImage: "clock",
                description: Text("Your saved day routes will appear here.")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.sortedRoutes) { route in
                        RouteRow(item: route)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 110)
            }
        }
    }
}
