//
//  SignInView.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import SwiftData
import SwiftUI

struct SignInView: View {
    @Binding var path: NavigationPath
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
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
                    
                    // Error Message (from appState or local)
                    if let authError = appState.authErrorMessage {
                        Text(authError)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 32)
                
                // Sign In Button
                Button(action: signIn) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign In")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .contentShape(Rectangle())
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
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
            .onAppear {
                // Clear auth error message after displaying
                if appState.authErrorMessage != nil {
                    // Clear after a delay to ensure user sees it
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        appState.authErrorMessage = nil
                    }
                }
            }
    }
    
    // MARK: - Actions
    
    private func signIn() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                let session = try await authService.signIn(email: email, password: password)
                
                // Check if profile exists
                let profiles: [ProfileDTO] = try await authService.fetchProfiles(userId: session.userId)
                
                await MainActor.run {
                    // Clear any auth error message on successful sign-in
                    appState.authErrorMessage = nil
                    
                    if let existingProfile = profiles.first {
                        // Profile exists - user is fully set up
                        print("Existing profile found: \(existingProfile.username)")
                        appState.isAuthenticated = true
                        appState.currentUserId = session.userId
                        // TODO: Load profile into SwiftData
                        
                        // Sync activities from backend after sign-in
                        Task {
                            do {
                                try await ActivityService.shared.syncActivitiesFromBackend(
                                    for: session.userId,
                                    modelContext: modelContext,
                                    appState: appState
                                )
                                // Retry any pending activities that failed to sync
                                await ActivityService.shared.syncPendingActivities(
                                    for: session.userId,
                                    modelContext: modelContext,
                                    appState: appState
                                )
                            } catch {
                                // Log error but don't block sign-in (auth errors will have already logged out)
                                print("Failed to sync activities after sign-in: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        // No profile - navigate to profile creation
                        print("No profile found - navigating to profile creation")
                        path.append(OnboardingDestination.profileCreation(
                            userId: session.userId,
                            email: email,
                            username: "user_\(session.userId.prefix(8))"
                        ))
                    }
                    isLoading = false
                }
            } catch {
                // Use ErrorManager for user-friendly error messages
                ErrorManager.shared.logError(error, context: "Sign In")
                await MainActor.run {
                    errorMessage = error.userMessage
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
