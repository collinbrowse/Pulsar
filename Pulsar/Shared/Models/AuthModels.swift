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

/// Supabase auth session (sign-in or refresh response).
/// refreshToken is used to restore session across app launches.
struct Session: Codable, Sendable {
    let accessToken: String
    let userId: String
    /// Optional so existing session payloads without it remain valid (e.g. tests).
    let refreshToken: String?
    
    init(accessToken: String, userId: String, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.userId = userId
        self.refreshToken = refreshToken
    }
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case userId
        case refreshToken = "refresh_token"
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try c.decode(String.self, forKey: .accessToken)
        userId = (try c.decodeIfPresent([String: AnyCodable].self, forKey: .userId)?.compactMapValues { $0.value as? String }.values.first)
            ?? (try? c.decode(String.self, forKey: .userId))
            ?? (try (c.decode([String: Any].self, forKey: CodingKeys(stringValue: "user")!))["id"] as? String)
            ?? ""
        if userId.isEmpty, let user = try? c.decode(GoTrueUser.self, forKey: CodingKeys(stringValue: "user")!) {
            // GoTrue wraps user in "user" object
        }
        refreshToken = try c.decodeIfPresent(String.self, forKey: .refreshToken)
    }
}
