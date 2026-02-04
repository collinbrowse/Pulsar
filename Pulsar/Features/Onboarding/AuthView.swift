//
//  AuthView.swift
//  Pulsar
//
//  Sign in and sign up authentication flow
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    @State private var isSignUp = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "bolt.heart.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(LinearGradient.pulsarGradient)
                        
                        Text(isSignUp ? "Create Account" : "Welcome Back")
                            .font(.displaySmall)
                            .foregroundStyle(Color.textPrimary)
                        
                        Text(isSignUp ? "Start your fitness journey" : "Sign in to continue")
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.top, Spacing.xl)
                    
                    // Sign in with Apple
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    .padding(.horizontal, Spacing.lg)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.labelMedium)
                            .foregroundStyle(Color.textTertiary)
                            .padding(.horizontal, Spacing.sm)
                        
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, Spacing.lg)
                    
                    // Email form
                    VStack(spacing: Spacing.md) {
                        if isSignUp {
                            AuthTextField(
                                icon: "person",
                                placeholder: "Full Name",
                                text: $fullName
                            )
                        }
                        
                        AuthTextField(
                            icon: "envelope",
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        AuthTextField(
                            icon: "lock",
                            placeholder: "Password",
                            text: $password,
                            isSecure: true
                        )
                        
                        if isSignUp {
                            AuthTextField(
                                icon: "lock",
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                isSecure: true
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    
                    // Action button
                    PrimaryButton(
                        isSignUp ? "Create Account" : "Sign In",
                        isLoading: isLoading
                    ) {
                        Task {
                            await authenticate()
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1 : 0.6)
                    
                    // Toggle sign in/sign up
                    Button {
                        withAnimation(.pulsarSpring) {
                            isSignUp.toggle()
                            clearForm()
                        }
                    } label: {
                        HStack(spacing: Spacing.xxs) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundStyle(Color.textSecondary)
                            
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .foregroundStyle(Color.pulsarPrimary)
                                .fontWeight(.semibold)
                        }
                        .font(.bodyMedium)
                    }
                    
                    // Terms
                    if isSignUp {
                        Text("By creating an account, you agree to our Terms of Service and Privacy Policy.")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }
                    
                    Spacer(minLength: Spacing.xxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty &&
                   !password.isEmpty &&
                   !fullName.isEmpty &&
                   password == confirmPassword &&
                   password.count >= 8
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    // MARK: - Actions
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
        errorMessage = nil
    }
    
    @MainActor
    private func authenticate() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if isSignUp {
                let user = try await SupabaseClient.shared.signUp(
                    email: email,
                    password: password,
                    metadata: ["full_name": fullName]
                )
                appState.currentUserID = user.id
                appState.isAuthenticated = true
            } else {
                let session = try await SupabaseClient.shared.signIn(
                    email: email,
                    password: password
                )
                appState.currentUserID = session.userId
                appState.isAuthenticated = true
            }
            
            HapticFeedback.notification(.success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticFeedback.notification(.error)
        }
        
        isLoading = false
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // In production, send credential to Supabase for Apple Sign In
                let userId = credential.user
                let email = credential.email
                let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                
                Task { @MainActor in
                    appState.currentUserID = userId
                    appState.userProfile = UserProfile(
                        userID: userId,
                        username: email ?? "user_\(userId.prefix(8))",
                        fullName: fullName.isEmpty ? nil : fullName,
                        avatarURL: nil
                    )
                    appState.isAuthenticated = true
                    HapticFeedback.notification(.success)
                    dismiss()
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Auth Text Field

struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    @State private var isPasswordVisible = false
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.bodyMedium)
                .foregroundStyle(Color.textTertiary)
                .frame(width: 24)
            
            if isSecure && !isPasswordVisible {
                SecureField(placeholder, text: $text)
                    .textContentType(placeholder.contains("Confirm") ? .newPassword : .password)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textContentType(keyboardType == .emailAddress ? .emailAddress : .none)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
            }
            
            if isSecure {
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
}

#Preview {
    AuthView()
        .environment(AppState())
}
