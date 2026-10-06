//
//  ListViewState.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 14.06.2026.
//
import SwiftUI

/// The two modes of the List tab's top toggle.
enum ListMode: CaseIterable, Identifiable {
    case routes
    case spots

    var id: Self { self }

    var title: String {
        switch self {
            case .routes:
                return "Routes"
            case .spots:
                return "Spots"
        }
    }
}

/// What the "+" menu can create.
enum AddTarget: CaseIterable, Identifiable {
    case route
    case spot

    var id: Self { self }

    var title: String {
        switch self {
            case .route:
                return "New Route"
            case .spot:
                return "New Spot"
        }
    }

    var iconName: String {
        switch self {
            case .route:
                return "clock"
            case .spot:
                return "binoculars"
        }
    }
}

@Observable
class ListViewState {
    var mode: ListMode = .routes
}
