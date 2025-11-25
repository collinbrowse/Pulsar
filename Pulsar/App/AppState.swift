//
//  AppState.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import Foundation
import Observation

/// Root application state using TCA
@Observable
final class AppState: Sendable {
    // MARK: - Authentication
    
    var isAuthenticated: Bool = false
    var currentUserId: String?
    
    // MARK: - User Profile
    
    var userProfile: UserProfile?
    
    // MARK: - Feature States
    
    // Will be expanded in future milestones
    // var onboardingState: OnboardingState?
    // var feedState: FeedState?
    // etc.
    
    // MARK: - App Configuration
    
    var isConfigured: Bool {
        AppEnvironment.shared.isConfigured
    }
}

/// Temporary user profile model (will be replaced with SwiftData model)
struct UserProfile: Sendable, Codable {
    let userId: String
    let username: String
    let fullName: String?
    let avatarURL: String?
}

