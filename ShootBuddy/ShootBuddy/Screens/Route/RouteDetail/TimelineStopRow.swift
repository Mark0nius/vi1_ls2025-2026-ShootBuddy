//
//  TimelineStopRow.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 18.06.2026.
//

import SwiftUI

/// A row in the route timeline showing a single stop with its arrival time and details
struct TimelineStopRow: View {
    let stop: RouteStop
    let isFirst: Bool
    let isLast: Bool
    let viewModel: RouteDetailViewModel
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            timelineLine
            
            if let onTap = onTap {
                Button(action: onTap) {
                    stopContentCard
                }
                .buttonStyle(.plain)
            } else {
                stopContentCard
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Components
    
    private var timelineLine: some View {
        VStack(spacing: 0) {
            if !isFirst {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 2)
            }
            
            Circle()
                .fill(Color.blue)
                .frame(width: 12, height: 12)
            
            if !isLast {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 2)
            }
        }
        .frame(width: 12)
    }
    
    private var stopContentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.formattedTime(stop.arrivalTime))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stop.spot.name)
                    .font(.system(size: 20, weight: .bold))
                
                if let note = stop.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                
                // Display photos if available
                if !stop.spot.photos.isEmpty {
                    photoPreview(photos: stop.spot.photos)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    @ViewBuilder
    private func photoPreview(photos: [Photo]) -> some View {
        HStack(spacing: 8) {
            ForEach(photos.prefix(2)) { photo in
                if let uiImage = UIImage(data: photo.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.top, 4)
    }
}
