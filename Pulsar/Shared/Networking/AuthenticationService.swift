//
//  AuthenticationService.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.collinbrowse.Pulsar", category: "Auth")

/// Authentication service handling sign up, sign in, and profile management
@MainActor
final class AuthenticationService: Sendable {
    static let shared = AuthenticationService()
    
    private let supabaseClient = SupabaseClient.shared
    private let keychain = KeychainManager.shared
    private var currentSession: Session?
    
    private let sessionKey = "auth_session"
    
    private init() {
        // Try to restore session from Keychain on initialization
        restoreSession()
    }
    
    // MARK: - Authentication State
    
    var isAuthenticated: Bool {
        currentSession != nil
    }
    
    var currentUserId: String? {
        currentSession?.userId
    }
    
    var accessToken: String? {
        currentSession?.accessToken
    }
    
    /// Refresh the access token if it's expired or about to expire
    func refreshTokenIfNeeded() async throws {
        guard let session = currentSession else {
            throw AuthError.notAuthenticated
        }
        
        // Check if token is expired or will expire soon
        guard session.isExpired else {
            logger.debug("Token is still valid, no refresh needed")
            return
        }
        
        logger.info("🔄 Token expired or expiring soon, refreshing...")
        
        do {
            let newSession = try await supabaseClient.refreshToken(refreshToken: session.refreshToken)
            
            // Update session in memory and Keychain
            currentSession = newSession
            try saveSession(newSession)
            
            logger.info("✅ Token refreshed successfully")
        } catch {
            logger.error("❌ Failed to refresh token: \(error.localizedDescription)")
            // If refresh fails, clear session and require re-authentication
            signOut()
            throw AuthError.notAuthenticated
        }
    }
    
    /// Get a valid access token, refreshing if necessary
    func getValidAccessToken() async throws -> String {
        // Ensure session is restored from Keychain first
        if currentSession == nil {
            restoreSession()
        }
        
        guard let session = currentSession else {
            logger.error("❌ No session found when trying to get access token")
            throw AuthError.notAuthenticated
        }
        
        try await refreshTokenIfNeeded()
        guard let token = accessToken else {
            logger.error("❌ Access token is nil after refresh")
            throw AuthError.notAuthenticated
        }
        return token
    }
    
    // MARK: - Sign Up
    
    func signUp(
        email: String,
        password: String,
        username: String,
        fullName: String?
    ) async throws -> User {
        logger.info("Signing up user: \(email)")
        
        // Validate inputs
        try validateEmail(email)
        try validatePassword(password)
        try validateUsername(username)
        
        // Sign up with Supabase
        let metadata: [String: Any] = [
            "username": username,
            "full_name": fullName ?? ""
        ]
        
        let user = try await supabaseClient.signUp(
            email: email,
            password: password,
            metadata: metadata
        )
        
        logger.info("User signed up successfully: \(user.id)")
        
        // Track analytics
        ObservabilityManager.shared.track(event: "user_signed_up", properties: [
            "user_id": user.id,
            "username": username
        ])
        
        return user
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws -> Session {
        logger.info("Signing in user: \(email)")
        
        // Validate inputs
        try validateEmail(email)
        
        // Sign in with Supabase
        let session = try await supabaseClient.signIn(email: email, password: password)
        
        // Store session in memory and Keychain
        currentSession = session
        try saveSession(session)
        
        logger.info("User signed in successfully: \(session.userId)")
        
        // Track analytics
        ObservabilityManager.shared.track(event: "user_signed_in", properties: [
            "user_id": session.userId
        ])
        
        // Identify user for analytics
        ObservabilityManager.shared.identifyUser(session.userId)
        
        return session
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        logger.info("Signing out user")
        currentSession = nil
        keychain.delete(key: sessionKey)
        
        ObservabilityManager.shared.track(event: "user_signed_out")
    }
    
    // MARK: - Session Persistence
    
    private func saveSession(_ session: Session) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(session)
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        try keychain.save(key: sessionKey, value: jsonString)
        logger.info("Session saved to Keychain")
    }
    
    private func restoreSession() {
        do {
            guard let jsonString = try keychain.load(key: sessionKey),
                  let data = jsonString.data(using: .utf8) else {
                logger.info("No saved session found in Keychain")
                currentSession = nil
                return
            }
            
            let decoder = JSONDecoder()
            let session = try decoder.decode(Session.self, from: data)
            
            // Verify session is still valid by checking token expiration
            // For now, we'll restore it and let API calls fail if expired
            currentSession = session
            logger.info("✅ Session restored from Keychain: \(session.userId)")
        } catch {
            logger.warning("❌ Failed to restore session from Keychain: \(error.localizedDescription)")
            // Clear invalid session
            currentSession = nil
            keychain.delete(key: sessionKey)
        }
    }
    
    /// Restore session and update app state (called on app launch)
    func restoreSessionIfNeeded(appState: AppState) {
        // Ensure session is restored from Keychain first
        restoreSession()
        
        if let session = currentSession {
            appState.isAuthenticated = true
            appState.currentUserId = session.userId
            logger.info("Session restored, user authenticated: \(session.userId)")
        } else {
            appState.isAuthenticated = false
            appState.currentUserId = nil
            logger.info("No session found, user not authenticated")
        }
    }
    
    // MARK: - Profile Management
    
    func fetchProfiles(userId: String) async throws -> [ProfileDTO] {
        logger.info("Fetching profiles for user: \(userId)")
        
        // Get valid access token, refreshing if necessary
        let token = try await getValidAccessToken()
        
        let profiles: [ProfileDTO] = try await supabaseClient.fetch(
            from: "profiles",
            filter: ["user_id": userId],
            accessToken: token,
            schema: "public"
        )
        
        return profiles
    }
    
    func fetchProfile(userId: String) async throws -> ProfileDTO {
        logger.info("Fetching profile for user: \(userId)")
        
        let profiles = try await fetchProfiles(userId: userId)
        
        guard let profile = profiles.first else {
            throw AuthError.profileNotFound
        }
        
        return profile
    }
    
    func updateProfile(_ profile: ProfileDTO) async throws {
        logger.info("Upserting profile for user: \(profile.userId)")
        
        // Get valid access token, refreshing if necessary
        let token = try await getValidAccessToken()
        
        // Upsert profile (create if not exists, update if exists)
        try await supabaseClient.upsert(
            table: "profiles",
            data: profile,
            accessToken: token,
            schema: "public"
        )
        
        logger.info("Profile upserted successfully")
        
        ObservabilityManager.shared.track(event: "profile_updated", properties: [
            "user_id": profile.userId
        ])
    }
    
    // MARK: - Validation
    
    private func validateEmail(_ email: String) throws {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            throw AuthError.invalidEmail
        }
    }
    
    private func validatePassword(_ password: String) throws {
        guard password.count >= 8 else {
            throw AuthError.passwordTooShort
        }
    }
    
    private func validateUsername(_ username: String) throws {
        guard username.count >= 3 else {
            throw AuthError.usernameTooShort
        }
        
        guard username.count <= 30 else {
            throw AuthError.usernameTooLong
        }
        
        let usernameRegex = "^[a-zA-Z0-9_-]+$"
        let usernamePredicate = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
        
        guard usernamePredicate.evaluate(with: username) else {
            throw AuthError.invalidUsername
        }
    }
}

// MARK: - Errors

enum AuthError: Error, LocalizedError {
    case notAuthenticated
    case profileNotFound
    case invalidEmail
    case passwordTooShort
    case usernameTooShort
    case usernameTooLong
    case invalidUsername
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .profileNotFound:
            return "Profile not found"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .passwordTooShort:
            return "Password must be at least 8 characters"
        case .usernameTooShort:
            return "Username must be at least 3 characters"
        case .usernameTooLong:
            return "Username must be no more than 30 characters"
        case .invalidUsername:
            return "Username can only contain letters, numbers, hyphens, and underscores"
        }
    }
}

