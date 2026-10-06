//
//  ListViewModel.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//
import SwiftUI

@Observable
class ListViewModel {
    var state: ListViewState = ListViewState()

    /// The Spots tab's view model, owned here so the view stays presentational.
    let spotViewModel: SpotViewModel = SpotViewModel()

    // The Routes tab's view model, owned here so route changes can refresh the list.
    let routeViewModel: RouteViewModel = RouteViewModel()
}
