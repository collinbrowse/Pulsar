//
//  RootView.swift
//  Pulsar
//
//  Root view that handles authentication state. Shows a loading screen until
//  we've determined auth; then either main app or onboarding. Logged-in users
//  never see onboarding; logged-out users never see the main tab bar.
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        Group {
            if !appState.hasDeterminedAuthState {
                AuthLoadingView()
                    .transition(.opacity)
            } else if appState.isAuthenticated {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity
                    ))
            } else {
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeOut(duration: 0.35), value: appState.hasDeterminedAuthState)
        .animation(.easeOut(duration: 0.35), value: appState.isAuthenticated)
    }
}

#Preview("Loading") {
    RootView()
        .environment(AppState())
}

#Preview("Authenticated") {
    let state = AppState()
    state.isAuthenticated = true
    state.hasDeterminedAuthState = true

    return RootView()
        .environment(state)
}

#Preview("Not Authenticated") {
    let state = AppState()
    state.hasDeterminedAuthState = true
    return RootView()
        .environment(state)
}
