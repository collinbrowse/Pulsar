//
//  SocialService.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.collinbrowse.Pulsar", category: "SocialService")

/// Service for managing social interactions (follows, kudos, comments)
@MainActor
final class SocialService: Sendable {
    static let shared = SocialService()
    
    private init() {}
    
    // MARK: - Follows
    
    /// Follow a user
    func followUser(
        followerId: String,
        followingId: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("👥 Following user: \(followingId)")
        
        // Check if already following
        let descriptor = FetchDescriptor<Follow>(
            predicate: #Predicate { follow in
                follow.followerId == followerId && follow.followingId == followingId
            }
        )
        
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else {
            logger.warning("Already following this user")
            return
        }
        
        // Create follow relationship
        let follow = Follow(followerId: followerId, followingId: followingId)
        modelContext.insert(follow)
        try modelContext.save()
        
        // TODO: Sync to backend
        // let dto = follow.toDTO()
        // try await supabaseClient.insert("follows", data: dto)
        
        ObservabilityManager.shared.track(event: "user_followed", properties: [
            "following_id": followingId
        ])
        
        logger.info("✅ Successfully followed user")
    }
    
    /// Unfollow a user
    func unfollowUser(
        followerId: String,
        followingId: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("👥 Unfollowing user: \(followingId)")
        
        let descriptor = FetchDescriptor<Follow>(
            predicate: #Predicate { follow in
                follow.followerId == followerId && follow.followingId == followingId
            }
        )
        
        let follows = try modelContext.fetch(descriptor)
        for follow in follows {
            modelContext.delete(follow)
        }
        try modelContext.save()
        
        // TODO: Sync to backend
        
        ObservabilityManager.shared.track(event: "user_unfollowed", properties: [
            "following_id": followingId
        ])
        
        logger.info("✅ Successfully unfollowed user")
    }
    
    /// Check if user is following another user
    func isFollowing(
        followerId: String,
        followingId: String,
        modelContext: ModelContext
    ) throws -> Bool {
        let descriptor = FetchDescriptor<Follow>(
            predicate: #Predicate { follow in
                follow.followerId == followerId && follow.followingId == followingId
            }
        )
        
        let follows = try modelContext.fetch(descriptor)
        return !follows.isEmpty
    }
    
    /// Get follower count for a user
    func getFollowerCount(
        userId: String,
        modelContext: ModelContext
    ) throws -> Int {
        let descriptor = FetchDescriptor<Follow>(
            predicate: #Predicate { follow in
                follow.followingId == userId
            }
        )
        
        return try modelContext.fetchCount(descriptor)
    }
    
    /// Get following count for a user
    func getFollowingCount(
        userId: String,
        modelContext: ModelContext
    ) throws -> Int {
        let descriptor = FetchDescriptor<Follow>(
            predicate: #Predicate { follow in
                follow.followerId == userId
            }
        )
        
        return try modelContext.fetchCount(descriptor)
    }
    
    // MARK: - Kudos
    
    /// Give a kudo to an activity
    func giveKudo(
        userId: String,
        activityId: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("❤️ Giving kudo to activity: \(activityId)")
        
        // Check if already kudoed
        let descriptor = FetchDescriptor<Kudo>(
            predicate: #Predicate { kudo in
                kudo.userId == userId && kudo.activityId == activityId
            }
        )
        
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else {
            logger.warning("Already kudoed this activity")
            return
        }
        
        // Create kudo
        let kudo = Kudo(userId: userId, activityId: activityId)
        modelContext.insert(kudo)
        try modelContext.save()
        
        // TODO: Sync to backend
        
        ObservabilityManager.shared.track(event: "kudo_given", properties: [
            "activity_id": activityId
        ])
        
        logger.info("✅ Kudo given successfully")
    }
    
    /// Remove a kudo from an activity
    func removeKudo(
        userId: String,
        activityId: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("❤️ Removing kudo from activity: \(activityId)")
        
        let descriptor = FetchDescriptor<Kudo>(
            predicate: #Predicate { kudo in
                kudo.userId == userId && kudo.activityId == activityId
            }
        )
        
        let kudos = try modelContext.fetch(descriptor)
        for kudo in kudos {
            modelContext.delete(kudo)
        }
        try modelContext.save()
        
        // TODO: Sync to backend
        
        logger.info("✅ Kudo removed successfully")
    }
    
    /// Get kudo count for an activity
    func getKudoCount(
        activityId: String,
        modelContext: ModelContext
    ) throws -> Int {
        let descriptor = FetchDescriptor<Kudo>(
            predicate: #Predicate { kudo in
                kudo.activityId == activityId
            }
        )
        
        return try modelContext.fetchCount(descriptor)
    }
    
    /// Check if user has kudoed an activity
    func hasKudoed(
        userId: String,
        activityId: String,
        modelContext: ModelContext
    ) throws -> Bool {
        let descriptor = FetchDescriptor<Kudo>(
            predicate: #Predicate { kudo in
                kudo.userId == userId && kudo.activityId == activityId
            }
        )
        
        let kudos = try modelContext.fetch(descriptor)
        return !kudos.isEmpty
    }
    
    // MARK: - Comments
    
    /// Add a comment to an activity
    func addComment(
        userId: String,
        activityId: String,
        text: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("💬 Adding comment to activity: \(activityId)")
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SocialServiceError.emptyComment
        }
        
        // Create comment
        let comment = Comment(userId: userId, activityId: activityId, text: text)
        modelContext.insert(comment)
        try modelContext.save()
        
        // TODO: Sync to backend
        
        ObservabilityManager.shared.track(event: "comment_added", properties: [
            "activity_id": activityId,
            "comment_length": text.count
        ])
        
        logger.info("✅ Comment added successfully")
    }
    
    /// Get comments for an activity
    func getComments(
        activityId: String,
        modelContext: ModelContext
    ) throws -> [Comment] {
        let descriptor = FetchDescriptor<Comment>(
            predicate: #Predicate { comment in
                comment.activityId == activityId
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// Delete a comment
    func deleteComment(
        commentID: String,
        userId: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("🗑️ Deleting comment: \(commentID)")
        
        let descriptor = FetchDescriptor<Comment>(
            predicate: #Predicate { comment in
                comment.id == commentID && comment.userId == userId
            }
        )
        
        let comments = try modelContext.fetch(descriptor)
        guard let comment = comments.first else {
            throw SocialServiceError.commentNotFound
        }
        
        modelContext.delete(comment)
        try modelContext.save()
        
        // TODO: Sync to backend
        
        logger.info("✅ Comment deleted successfully")
    }
    
    // MARK: - Feed
    
    /// Get feed items for a user (activities from followed users)
    func getFeed(
        userId: String,
        modelContext: ModelContext
    ) throws -> [FeedItem] {
        // Get list of users the current user follows
        let followDescriptor = FetchDescriptor<Follow>(
            predicate: #Predicate { follow in
                follow.followerId == userId
            }
        )
        
        let follows = try modelContext.fetch(followDescriptor)
        let followingIds = follows.map { $0.followingId }
        
        // Get activities from followed users
        let activityDescriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                followingIds.contains(activity.userId) && !activity.isPrivate
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        let activities = try modelContext.fetch(activityDescriptor)
        
        // Build feed items
        var feedItems: [FeedItem] = []
        for activity in activities.prefix(50) { // Limit to 50 items
            // TODO: Fetch actual profile from database
            let profile = Profile(
                userId: activity.userId,
                username: "athlete\(activity.userId.prefix(8))",
                email: "athlete@example.com"
            )
            
            let kudosCount = try getKudoCount(activityId: activity.id, modelContext: modelContext)
            let hasUserKudoed = try hasKudoed(userId: userId, activityId: activity.id, modelContext: modelContext)
            let comments = try getComments(activityId: activity.id, modelContext: modelContext)
            
            let feedItem = FeedItem(
                id: activity.id,
                activity: activity,
                profile: profile,
                kudosCount: kudosCount,
                commentsCount: comments.count,
                hasUserKudoed: hasUserKudoed,
                recentComments: []
            )
            
            feedItems.append(feedItem)
        }
        
        return feedItems
    }
}

// MARK: - Errors

enum SocialServiceError: Error, LocalizedError {
    case emptyComment
    case commentNotFound
    case alreadyFollowing
    case notFollowing
    
    var errorDescription: String? {
        switch self {
        case .emptyComment:
            return "Comment cannot be empty"
        case .commentNotFound:
            return "Comment not found or you don't have permission to delete it"
        case .alreadyFollowing:
            return "You are already following this user"
        case .notFollowing:
            return "You are not following this user"
        }
    }
}

