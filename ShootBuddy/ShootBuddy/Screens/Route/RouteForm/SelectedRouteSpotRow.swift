//
//  SelectedRouteSpotRow.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 15.06.2026.
//

import SwiftUI
import UIKit

// Card showing a spot already selected for the route draft.
struct SelectedRouteSpotRow: View {
    let spot: Spot
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(spot.name)
                        .font(.subheadline.bold())

                    Text(spot.address.formatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.red, in: Circle())
                }
            }

            spotImage
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(10)
    }

    private var spotImage: some View {
        Group {
            if
                let imageData = spot.photos.first?.imageData,
                let image = UIImage(data: imageData)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
    }
}

