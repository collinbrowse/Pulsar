//
//  Profile.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import Foundation
import SwiftData

/// User profile model stored locally with SwiftData
@Model
final class Profile {
    @Attribute(.unique) var userID: String
    var username: String
    var fullName: String?
    var email: String
    var avatarURL: String?
    var gender: Gender?
    var weightKg: Double?
    var birthYear: Int?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        userID: String,
        username: String,
        email: String,
        fullName: String? = nil,
        avatarURL: String? = nil,
        gender: Gender? = nil,
        weightKg: Double? = nil,
        birthYear: Int? = nil
    ) {
        self.userID = userID
        self.username = username
        self.email = email
        self.fullName = fullName
        self.avatarURL = avatarURL
        self.gender = gender
        self.weightKg = weightKg
        self.birthYear = birthYear
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Supporting Types

enum Gender: String, Codable, CaseIterable, Sendable {
    case male
    case female
    case other
    case preferNotToSay = "prefer_not_to_say"
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

// MARK: - API Transfer Object

struct ProfileDTO: Codable, Sendable {
    let userId: String
    let username: String
    let fullName: String?
    let avatarUrl: String?
    let gender: String?
    let weightKg: Double?
    let birthYear: Int?
    let createdAt: Date?
    let updatedAt: Date?
    
    // Note: We rely on JSONDecoder's .convertFromSnakeCase strategy
    // No custom CodingKeys needed - the decoder handles user_id -> userId automatically
}

// MARK: - Conversion Extensions

extension Profile {
    func toDTO() -> ProfileDTO {
        ProfileDTO(
            userId: userID,
            username: username,
            fullName: fullName,
            avatarUrl: avatarURL,
            gender: gender?.rawValue,
            weightKg: weightKg,
            birthYear: birthYear,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    static func fromDTO(_ dto: ProfileDTO, email: String) -> Profile {
        Profile(
            userID: dto.userId,
            username: dto.username,
            email: email,
            fullName: dto.fullName,
            avatarURL: dto.avatarUrl,
            gender: Gender(rawValue: dto.gender ?? ""),
            weightKg: dto.weightKg,
            birthYear: dto.birthYear
        )
    }
}

