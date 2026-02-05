//
//  AppState.swift
//  Pulsar
//
//  Global application state using Observable pattern
//

import Foundation
import Observation

/// Root application state (main-actor isolated for Swift 6 concurrency)
@MainActor
@Observable
final class AppState {
    // MARK: - Authentication
    
    /// Whether the user is currently authenticated
    var isAuthenticated: Bool = false
    
    /// Current user's ID (from Supabase Auth)
    var currentUserID: String?
    
    /// Current user's access token
    var accessToken: String?
    
    // MARK: - User Profile
    
    /// Cached user profile for quick access
    var userProfile: UserProfile?
    
    // MARK: - App State
    
    /// Whether the app is currently loading data
    var isLoading: Bool = false
    
    /// Global error message to display
    var errorMessage: String?
    
    /// Whether to show the global error alert
    var showError: Bool = false
    
    // MARK: - App Configuration
    
    /// Whether the environment is properly configured
    var isConfigured: Bool {
        AppEnvironment.shared.isConfigured
    }
    
    // MARK: - Initialization
    
    init() {
        // Load any persisted authentication state
        loadPersistedState()
        // UI testing: allow launching in authenticated state
        if ProcessInfo.processInfo.arguments.contains("--authenticated") {
            isAuthenticated = true
            currentUserID = "ui-test-user"
        }
    }
    
    // MARK: - State Management
    
    /// Sign out the user and clear state
    func signOut() {
        isAuthenticated = false
        currentUserID = nil
        accessToken = nil
        userProfile = nil
        clearPersistedState()
    }
    
    /// Set authentication state after successful login
    func setAuthenticated(userId: String, accessToken: String, profile: UserProfile? = nil) {
        self.currentUserID = userId
        self.accessToken = accessToken
        self.userProfile = profile
        self.isAuthenticated = true
        persistState()
    }
    
    /// Show a global error message
    func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    // MARK: - Persistence
    
    private func loadPersistedState() {
        // In production, load from Keychain
        // For now, user will need to re-authenticate each launch
    }
    
    private func persistState() {
        // In production, save to Keychain
    }
    
    private func clearPersistedState() {
        // In production, clear Keychain
    }
}
