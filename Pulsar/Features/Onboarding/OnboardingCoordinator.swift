//
//  OnboardingCoordinator.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import SwiftUI

/// Manages the onboarding navigation flow
struct OnboardingCoordinator: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(path: $path)
                .navigationDestination(for: OnboardingDestination.self) { destination in
                    switch destination {
                    case .welcome:
                        WelcomeView(path: $path)
                    case .signIn:
                        SignInView(path: $path)
                    case .signUp:
                        SignUpView(path: $path)
                    case .profileCreation(let userId, let email, let username):
                        ProfileCreationView(userId: userId, email: email, username: username, path: $path)
                    }
                }
        }
    }
}

#Preview {
    OnboardingCoordinator()
}

