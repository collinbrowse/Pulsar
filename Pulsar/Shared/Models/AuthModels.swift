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
    /// When the access token should be treated as expired (refresh ~2 min before).
    private(set) var accessTokenExpiresAt: Date?
    
    init(
        accessToken: String,
        userId: String,
        refreshToken: String? = nil,
        expiresInSeconds: Int? = nil
    ) {
        self.accessToken = accessToken
        self.userId = userId
        self.refreshToken = refreshToken
        if let sec = expiresInSeconds, sec > 0 {
            self.accessTokenExpiresAt = Date().addingTimeInterval(TimeInterval(sec - 120))
        } else {
            self.accessTokenExpiresAt = nil
        }
    }
    
    var isExpired: Bool {
        guard let accessTokenExpiresAt else { return false }
        return Date() >= accessTokenExpiresAt
    }
    
    enum CodingKeys: String, CodingKey {
        case accessToken
        case userId
        case refreshToken
        case accessTokenExpiresAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        userId = try container.decode(String.self, forKey: .userId)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        accessTokenExpiresAt = try container.decodeIfPresent(Date.self, forKey: .accessTokenExpiresAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(refreshToken, forKey: .refreshToken)
        try container.encodeIfPresent(accessTokenExpiresAt, forKey: .accessTokenExpiresAt)
    }
}
