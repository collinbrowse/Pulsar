//
//  SignInView.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import SwiftUI

struct SignInView: View {
    @Binding var path: NavigationPath
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let authService = AuthenticationService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.system(size: 32, weight: .bold))
                    Text("Sign in to continue")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("you@example.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Email")
                            .accessibilityIdentifier("Email")
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        SecureField("••••••••", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Password")
                            .accessibilityIdentifier("Password")
                    }
                    
                    // Error Message
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 32)
                
                // Sign In Button
                Button(action: signIn) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(email.isEmpty || password.isEmpty ? Color(.systemGray4) : .blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 32)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .accessibilityIdentifier("Sign In")
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                    Text("or")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 8)
                
                // Apple Sign In (Placeholder)
                Button(action: signInWithApple) {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Sign in with Apple")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.black)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Actions
    
    private func signIn() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                let session = try await authService.signIn(email: email, password: password)
                
                // Fetch existing profile or navigate to profile creation
                await MainActor.run {
                    // For now, always go to profile creation
                    // TODO: Check if profile exists and go to main app if it does
                    path.append(OnboardingDestination.profileCreation(
                        userID: session.userId,
                        email: email,
                        username: "existing_user"
                    ))
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func signInWithApple() {
        // TODO: Implement Apple Sign In
        errorMessage = "Apple Sign In coming soon"
    }
}

#Preview {
    NavigationStack {
        SignInView(path: .constant(NavigationPath()))
    }
}

