//
//  RootView.swift
//  Pulsar
//
//  Root view that handles authentication state
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
    }
}

#Preview("Authenticated") {
    let state = AppState()
    state.isAuthenticated = true
    
    return RootView()
        .environment(state)
}

#Preview("Not Authenticated") {
    RootView()
        .environment(AppState())
}
