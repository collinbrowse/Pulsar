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
    
    /// True only after we've tried restoring session on launch. Keeps user on loading screen until we know auth state.
    var hasDeterminedAuthState: Bool = false
    
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
        // UI testing: allow launching in authenticated state (skip loading screen)
        if ProcessInfo.processInfo.arguments.contains("--authenticated") {
            isAuthenticated = true
            currentUserID = "ui-test-user"
            hasDeterminedAuthState = true
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
    
    /// Set authentication state after successful login (and persist so user stays logged in).
    func setAuthenticated(userId: String, accessToken: String, refreshToken: String? = nil, profile: UserProfile? = nil) {
        self.currentUserID = userId
        self.accessToken = accessToken
        self.userProfile = profile
        self.isAuthenticated = true
        persistState(userId: userId, accessToken: accessToken, refreshToken: refreshToken)
    }
    
    /// Show a global error message
    func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    // MARK: - Persistence
    
    /// Call once on launch to restore session from Keychain (e.g. refresh token).
    /// If a stored refresh token is valid, the user is signed in without showing login.
    func restoreSessionIfNeeded() async {
        defer { hasDeterminedAuthState = true }
        guard let stored = KeychainStorage.loadSession() else { return }
        // Prefer refreshing so we get a fresh access token; if no refresh token, apply stored access token (may be expired).
        if let refreshToken = stored.refreshToken {
            do {
                let session = try await SupabaseClient.shared.refreshSession(refreshToken: refreshToken)
                setAuthenticated(
                    userId: session.userId,
                    accessToken: session.accessToken,
                    refreshToken: session.refreshToken,
                    profile: nil
                )
            } catch {
                clearPersistedState()
            }
            return
        }
        // Legacy: only access token stored (e.g. from before we added refresh).
        setAuthenticated(
            userId: stored.userId,
            accessToken: stored.accessToken,
            refreshToken: nil,
            profile: nil
        )
    }
    
    private func loadPersistedState() {
        // Session is restored asynchronously in restoreSessionIfNeeded() so we can refresh the token.
    }
    
    private func persistState(userId: String? = nil, accessToken: String? = nil, refreshToken: String? = nil) {
        let uid = userId ?? currentUserID
        let token = accessToken ?? self.accessToken
        guard let uid = uid, let token = token else { return }
        KeychainStorage.saveSession(userId: uid, accessToken: token, refreshToken: refreshToken)
    }
    
    private func clearPersistedState() {
        KeychainStorage.clearSession()
    }
}
