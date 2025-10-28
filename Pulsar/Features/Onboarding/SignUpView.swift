//
//  SignUpView.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import SwiftUI

struct SignUpView: View {
    @Binding var path: NavigationPath
    @Environment(AppState.self) private var appState
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let authService = AuthenticationService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.system(size: 32, weight: .bold))
                    Text("Join the Pulsar community")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Form
                VStack(spacing: 16) {
                    // Username Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("athlete123", text: $username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Username")
                            .accessibilityIdentifier("Username")
                        
                        Text("3-30 characters, letters, numbers, - and _ only")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Full Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("John Doe", text: $fullName)
                            .textContentType(.name)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Full Name")
                            .accessibilityIdentifier("Full Name")
                    }
                    
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
                            .textContentType(nil) // Disable automatic password suggestion
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Password")
                            .accessibilityIdentifier("Password")
                        
                        Text("Minimum 8 characters")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        SecureField("••••••••", text: $confirmPassword)
                            .textContentType(nil) // Disable automatic password suggestion
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Confirm Password")
                            .accessibilityIdentifier("Confirm Password")
                    }
                    
                    // Password Match Indicator
                    if !password.isEmpty && !confirmPassword.isEmpty {
                        HStack {
                            Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(password == confirmPassword ? .green : .red)
                            Text(password == confirmPassword ? "Passwords match" : "Passwords don't match")
                                .font(.caption)
                                .foregroundStyle(password == confirmPassword ? .green : .red)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                
                // Sign Up Button
                Button(action: signUp) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Account")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? .blue : Color(.systemGray4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 32)
                .disabled(isLoading || !isFormValid)
                .accessibilityIdentifier("Create Account")
                
                // Terms
                Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword
    }
    
    // MARK: - Actions
    
    private func signUp() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                let user = try await authService.signUp(
                    email: email,
                    password: password,
                    username: username,
                    fullName: fullName.isEmpty ? nil : fullName
                )
                
                // Sign in immediately after signup to get session
                let session = try await authService.signIn(email: email, password: password)
                
                // Navigate to profile creation
                await MainActor.run {
                    path.append(OnboardingDestination.profileCreation(
                        userID: session.userId,
                        email: email,
                        username: username
                    ))
                }
            } catch {
                // Check if error is "user already exists"
                let errorDescription = error.localizedDescription.lowercased()
                if errorDescription.contains("user_already_exists") || 
                   errorDescription.contains("user already registered") ||
                   errorDescription.contains("already exists") {
                    // Gracefully handle by signing in instead
                    await handleExistingUser()
                } else {
                    // Show other errors normally
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        isLoading = false
                    }
                }
            }
        }
    }
    
    /// Gracefully handle sign-up attempt with existing account by signing in
    private func handleExistingUser() async {
        print("ℹ️ User already exists - attempting sign-in instead")
        
        do {
            // Attempt to sign in with provided credentials
            let session = try await authService.signIn(email: email, password: password)
            
            // Check if profile exists
            let profiles: [ProfileDTO] = try await authService.fetchProfiles(userID: session.userId)
            
            await MainActor.run {
                if let existingProfile = profiles.first {
                    // User has complete profile - go to main app
                    print("✅ Existing user signed in successfully - navigating to main app")
                    appState.isAuthenticated = true
                    appState.currentUserID = session.userId
                    path = NavigationPath() // Clear navigation stack
                } else {
                    // User exists but no profile - navigate to profile creation
                    print("ℹ️ Existing user needs to complete profile")
                    path.append(OnboardingDestination.profileCreation(
                        userID: session.userId,
                        email: email,
                        username: username
                    ))
                }
                isLoading = false
            }
        } catch {
            // Sign-in failed (wrong password, etc.) - show error
            await MainActor.run {
                errorMessage = "Account exists. Please check your password and try again, or use Sign In."
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView(path: .constant(NavigationPath()))
    }
}

