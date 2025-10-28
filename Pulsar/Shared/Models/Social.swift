//
//  Social.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import Foundation
import SwiftData

// MARK: - Follow

/// Represents a follower/following relationship between users
@Model
final class Follow {
    @Attribute(.unique) var id: String
    var followerID: String // User who is following
    var followingID: String // User being followed
    var createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        followerID: String,
        followingID: String
    ) {
        self.id = id
        self.followerID = followerID
        self.followingID = followingID
        self.createdAt = Date()
    }
}

// MARK: - Kudo

/// Represents a "like" or "kudo" on an activity
@Model
final class Kudo {
    @Attribute(.unique) var id: String
    var userID: String // User who gave the kudo
    var activityID: String // Activity that received the kudo
    var createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        userID: String,
        activityID: String
    ) {
        self.id = id
        self.userID = userID
        self.activityID = activityID
        self.createdAt = Date()
    }
}

// MARK: - Comment

/// Represents a comment on an activity
@Model
final class Comment {
    @Attribute(.unique) var id: String
    var userID: String // User who wrote the comment
    var activityID: String // Activity being commented on
    var text: String
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        userID: String,
        activityID: String,
        text: String
    ) {
        self.id = id
        self.userID = userID
        self.activityID = activityID
        self.text = text
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Feed Item

/// Represents an item in the social feed
struct FeedItem: Identifiable, Sendable {
    let id: String
    let activity: Activity
    let profile: Profile
    let kudosCount: Int
    let commentsCount: Int
    let hasUserKudoed: Bool
    let recentComments: [CommentWithProfile]
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(activity.startDate)
        let hours = Int(interval / 3600)
        let days = hours / 24
        
        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        }
    }
}

/// Comment with associated user profile
struct CommentWithProfile: Identifiable, Sendable {
    let id: String
    let comment: Comment
    let profile: Profile
}

// MARK: - DTOs for API

struct FollowDTO: Codable, Sendable {
    let id: String
    let followerId: String
    let followingId: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case followerId = "follower_id"
        case followingId = "following_id"
        case createdAt = "created_at"
    }
}

struct KudoDTO: Codable, Sendable {
    let id: String
    let userId: String
    let activityId: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case activityId = "activity_id"
        case createdAt = "created_at"
    }
}

struct CommentDTO: Codable, Sendable {
    let id: String
    let userId: String
    let activityId: String
    let text: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case activityId = "activity_id"
        case text
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Conversion Extensions

extension Follow {
    func toDTO() -> FollowDTO {
        FollowDTO(
            id: id,
            followerId: followerID,
            followingId: followingID,
            createdAt: createdAt
        )
    }
    
    static func fromDTO(_ dto: FollowDTO) -> Follow {
        Follow(
            id: dto.id,
            followerID: dto.followerId,
            followingID: dto.followingId
        )
    }
}

extension Kudo {
    func toDTO() -> KudoDTO {
        KudoDTO(
            id: id,
            userId: userID,
            activityId: activityID,
            createdAt: createdAt
        )
    }
    
    static func fromDTO(_ dto: KudoDTO) -> Kudo {
        Kudo(
            id: dto.id,
            userID: dto.userId,
            activityID: dto.activityId
        )
    }
}

extension Comment {
    func toDTO() -> CommentDTO {
        CommentDTO(
            id: id,
            userId: userID,
            activityId: activityID,
            text: text,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    static func fromDTO(_ dto: CommentDTO) -> Comment {
        Comment(
            id: dto.id,
            userID: dto.userId,
            activityID: dto.activityId,
            text: dto.text
        )
    }
}

