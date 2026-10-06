//
//  SplashView.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 17.06.2026.
//

import SwiftUI

struct SplashView: View {
    // Displays the app icon and app name during launch.
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("SplashAppIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(spacing: 12) {
                    Text("ShootBuddy")
                        .font(.title.bold())
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
