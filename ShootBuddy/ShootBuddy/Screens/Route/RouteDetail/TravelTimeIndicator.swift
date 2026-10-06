//
//  TravelTimeIndicator.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 18.06.2026.
//

import SwiftUI

/// Shows travel time between two route stops with transport mode icon
struct TravelTimeIndicator: View {
    let travelTime: TimeInterval
    let transportMode: TransportMode
    let viewModel: RouteDetailViewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            timelineConnector
            travelInfo
            Spacer()
        }
    }
    
    // MARK: - Components
    
    private var timelineConnector: some View {
        Rectangle()
            .fill(Color.blue.opacity(0.3))
            .frame(width: 2, height: 40)
            .frame(width: 12) // Center it in the timeline column
    }
    
    private var travelInfo: some View {
        HStack(spacing: 6) {
            Image(systemName: transportMode.icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            
            Text(viewModel.formattedTravelTime(travelTime))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }
}
