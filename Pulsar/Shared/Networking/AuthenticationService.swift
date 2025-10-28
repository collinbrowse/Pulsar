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
    private var currentSession: Session?
    
    private init() {}
    
    // MARK: - Authentication State
    
    var isAuthenticated: Bool {
        currentSession != nil
    }
    
    var currentUserID: String? {
        currentSession?.userId
    }
    
    var accessToken: String? {
        currentSession?.accessToken
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
        
        // Store session
        currentSession = session
        
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
        
        ObservabilityManager.shared.track(event: "user_signed_out")
    }
    
    // MARK: - Profile Management
    
    func fetchProfiles(userID: String) async throws -> [ProfileDTO] {
        logger.info("Fetching profiles for user: \(userID)")
        
        guard let token = accessToken else {
            throw AuthError.notAuthenticated
        }
        
        let profiles: [ProfileDTO] = try await supabaseClient.fetch(
            from: "profiles",
            filter: ["user_id": userID],
            accessToken: token
        )
        
        return profiles
    }
    
    func fetchProfile(userID: String) async throws -> ProfileDTO {
        logger.info("Fetching profile for user: \(userID)")
        
        let profiles = try await fetchProfiles(userID: userID)
        
        guard let profile = profiles.first else {
            throw AuthError.profileNotFound
        }
        
        return profile
    }
    
    func updateProfile(_ profile: ProfileDTO) async throws {
        logger.info("Upserting profile for user: \(profile.userId)")
        
        guard let token = accessToken else {
            throw AuthError.notAuthenticated
        }
        
        // Upsert profile (create if not exists, update if exists)
        try await supabaseClient.upsert(
            table: "profiles",
            data: profile,
            accessToken: token
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

