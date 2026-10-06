//
//  AppRootView.swift
//  ShootBuddy
//
//  Created by Libor Jevický on 17.06.2026.
//

import SwiftUI

struct AppRootView: View {
    // Controls whether the launch splash or the main app content is visible.
    @State private var isSplashVisible = true

    // Shows the splash first, then fades into the main app after a short delay.
    var body: some View {
        ZStack {
            if isSplashVisible {
                SplashView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isSplashVisible)
        .task {
            try? await Task.sleep(for: .seconds(1.4))
            isSplashVisible = false
        }
    }
}

#Preview {
    AppRootView()
}
