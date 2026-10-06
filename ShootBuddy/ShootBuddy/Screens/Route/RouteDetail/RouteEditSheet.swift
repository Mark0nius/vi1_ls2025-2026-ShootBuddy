//
//  RouteEditSheet.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 18.06.2026.
//

import SwiftUI

/// Sheet for editing an existing route
/// Owns its own `RouteFormViewModel` (created from the route), so the instance the
/// user edits is always the instance `saveRoute()` reads.
struct RouteEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: RouteFormViewModel

    private let onSaved: () -> Void
    private let onDeleted: () -> Void

    init(route: Route, onSaved: @escaping () -> Void, onDeleted: @escaping () -> Void) {
        self.viewModel = RouteFormViewModel(route: route)
        self.onSaved = onSaved
        self.onDeleted = onDeleted
    }

    var body: some View {
        NavigationStack {
            RouteFormView(
                viewModel: viewModel,
                onDelete: {
                    if viewModel.deleteRoute() {
                        dismiss()
                        onDeleted()
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            if await viewModel.saveRoute() {
                                onSaved()  // onSaved posts notification
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}
