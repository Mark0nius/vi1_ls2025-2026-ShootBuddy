//
//  AddSpotToRouteViewState.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 17.06.2026.
//

import SwiftUI

@Observable
class AddSpotToRouteViewState {
    var spot: Spot
    var routes: [Route] = []
    var isLoading: Bool = false
    
    init(spot: Spot) {
        self.spot = spot
    }
}
