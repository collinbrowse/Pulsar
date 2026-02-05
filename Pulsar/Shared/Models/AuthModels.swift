//
//  AuthModels.swift
//  Pulsar
//
//  Auth and API DTOs. Kept in a separate file so they are not inferred as MainActor.
//

import Foundation

/// User profile model for display purposes
struct UserProfile: Sendable, Codable, Equatable {
    let userID: String
    let username: String
    let fullName: String?
    let avatarURL: String?
    
    /// Display name - prefers full name over username
    var displayName: String {
        fullName ?? username
    }
}

/// Supabase auth user (signup response)
struct User: Codable, Sendable {
    let id: String
    let email: String
}

/// Supabase auth session (sign-in response)
struct Session: Codable, Sendable {
    let accessToken: String
    let userId: String
}
