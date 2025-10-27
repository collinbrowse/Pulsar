//
//  WelcomeView.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import SwiftUI

struct WelcomeView: View {
    @Binding var path: NavigationPath
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Icon/Logo
            Image(systemName: "figure.run")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            // Title
            Text("Pulsar")
                .font(.system(size: 48, weight: .bold))
            
            // Tagline
            Text("Track, compete, and connect with athletes worldwide")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // CTA Buttons
            VStack(spacing: 16) {
                Button(action: {
                    path.append(OnboardingDestination.signUp)
                }) {
                    Text("Create Account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    path.append(OnboardingDestination.signIn)
                }) {
                    Text("Sign In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden()
    }
}

// MARK: - Navigation Destinations

enum OnboardingDestination: Hashable {
    case welcome
    case signIn
    case signUp
    case profileCreation(userID: String, email: String, username: String)
}

#Preview {
    NavigationStack {
        WelcomeView(path: .constant(NavigationPath()))
    }
}

