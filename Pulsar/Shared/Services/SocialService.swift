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
        followerID: String,
        followingID: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("👥 Following user: \(followingID)")
        
        // Check if already following
        let descriptor = FetchDescriptor<Follow>(
            predicate: #Predicate { follow in
                follow.followerID == followerID && follow.followingID == followingID
            }
        )
        
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else {
            logger.warning("Already following this user")
            return
        }
        
        // Create follow relationship
        let follow = Follow(followerID: followerID, followingID: followingID)
        modelContext.insert(follow)
        try modelContext.save()
        
        // TODO: Sync to backend
        // let dto = follow.toDTO()
        // try await supabaseClient.insert("follows", data: dto)
        
        ObservabilityManager.shared.track(event: "user_followed", properties: [
            "following_id": followingID
        ])
        
        logger.info("✅ Successfully followed user")
    }
    
    /// Unfollow a user
    func unfollowUser(
        followerID: String,
        followingID: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("👥 Unfollowing user: \(followingID)")
        
        let descriptor = FetchDescriptor<Follow>(
            predicate: #Predicate { follow in
                follow.followerID == followerID && follow.followingID == followingID
            }
        )
        
        let follows = try modelContext.fetch(descriptor)
        for follow in follows {
            modelContext.delete(follow)
        }
        try modelContext.save()
        
        // TODO: Sync to backend
        
        ObservabilityManager.shared.track(event: "user_unfollowed", properties: [
            "following_id": followingID
        ])
        
        logger.info("✅ Successfully unfollowed user")
    }
    
    /// Check if user is following another user
    func isFollowing(
        followerID: String,
        followingID: String,
        modelContext: ModelContext
    ) throws -> Bool {
        let descriptor = FetchDescriptor<Follow>(
            predicate: #Predicate { follow in
                follow.followerID == followerID && follow.followingID == followingID
            }
        )
        
        let follows = try modelContext.fetch(descriptor)
        return !follows.isEmpty
    }
    
    /// Get follower count for a user
    func getFollowerCount(
        userID: String,
        modelContext: ModelContext
    ) throws -> Int {
        let descriptor = FetchDescriptor<Follow>(
            predicate: #Predicate { follow in
                follow.followingID == userID
            }
        )
        
        return try modelContext.fetchCount(descriptor)
    }
    
    /// Get following count for a user
    func getFollowingCount(
        userID: String,
        modelContext: ModelContext
    ) throws -> Int {
        let descriptor = FetchDescriptor<Follow>(
            predicate: #Predicate { follow in
                follow.followerID == userID
            }
        )
        
        return try modelContext.fetchCount(descriptor)
    }
    
    // MARK: - Kudos
    
    /// Give a kudo to an activity
    func giveKudo(
        userID: String,
        activityID: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("❤️ Giving kudo to activity: \(activityID)")
        
        // Check if already kudoed
        let descriptor = FetchDescriptor<Kudo>(
            predicate: #Predicate { kudo in
                kudo.userID == userID && kudo.activityID == activityID
            }
        )
        
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else {
            logger.warning("Already kudoed this activity")
            return
        }
        
        // Create kudo
        let kudo = Kudo(userID: userID, activityID: activityID)
        modelContext.insert(kudo)
        try modelContext.save()
        
        // TODO: Sync to backend
        
        ObservabilityManager.shared.track(event: "kudo_given", properties: [
            "activity_id": activityID
        ])
        
        logger.info("✅ Kudo given successfully")
    }
    
    /// Remove a kudo from an activity
    func removeKudo(
        userID: String,
        activityID: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("❤️ Removing kudo from activity: \(activityID)")
        
        let descriptor = FetchDescriptor<Kudo>(
            predicate: #Predicate { kudo in
                kudo.userID == userID && kudo.activityID == activityID
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
        activityID: String,
        modelContext: ModelContext
    ) throws -> Int {
        let descriptor = FetchDescriptor<Kudo>(
            predicate: #Predicate { kudo in
                kudo.activityID == activityID
            }
        )
        
        return try modelContext.fetchCount(descriptor)
    }
    
    /// Check if user has kudoed an activity
    func hasKudoed(
        userID: String,
        activityID: String,
        modelContext: ModelContext
    ) throws -> Bool {
        let descriptor = FetchDescriptor<Kudo>(
            predicate: #Predicate { kudo in
                kudo.userID == userID && kudo.activityID == activityID
            }
        )
        
        let kudos = try modelContext.fetch(descriptor)
        return !kudos.isEmpty
    }
    
    // MARK: - Comments
    
    /// Add a comment to an activity
    func addComment(
        userID: String,
        activityID: String,
        text: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("💬 Adding comment to activity: \(activityID)")
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SocialServiceError.emptyComment
        }
        
        // Create comment
        let comment = Comment(userID: userID, activityID: activityID, text: text)
        modelContext.insert(comment)
        try modelContext.save()
        
        // TODO: Sync to backend
        
        ObservabilityManager.shared.track(event: "comment_added", properties: [
            "activity_id": activityID,
            "comment_length": text.count
        ])
        
        logger.info("✅ Comment added successfully")
    }
    
    /// Get comments for an activity
    func getComments(
        activityID: String,
        modelContext: ModelContext
    ) throws -> [Comment] {
        let descriptor = FetchDescriptor<Comment>(
            predicate: #Predicate { comment in
                comment.activityID == activityID
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// Delete a comment
    func deleteComment(
        commentID: String,
        userID: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("🗑️ Deleting comment: \(commentID)")
        
        let descriptor = FetchDescriptor<Comment>(
            predicate: #Predicate { comment in
                comment.id == commentID && comment.userID == userID
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
        userID: String,
        modelContext: ModelContext
    ) throws -> [FeedItem] {
        // Get list of users the current user follows
        let followDescriptor = FetchDescriptor<Follow>(
            predicate: #Predicate { follow in
                follow.followerID == userID
            }
        )
        
        let follows = try modelContext.fetch(followDescriptor)
        let followingIDs = follows.map { $0.followingID }
        
        // Get activities from followed users
        let activityDescriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                followingIDs.contains(activity.userID) && !activity.isPrivate
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        let activities = try modelContext.fetch(activityDescriptor)
        
        // Build feed items
        var feedItems: [FeedItem] = []
        for activity in activities.prefix(50) { // Limit to 50 items
            // TODO: Fetch actual profile from database
            let profile = Profile(
                userID: activity.userID,
                username: "athlete\(activity.userID.prefix(8))",
                email: "athlete@example.com"
            )
            
            let kudosCount = try getKudoCount(activityID: activity.id, modelContext: modelContext)
            let hasUserKudoed = try hasKudoed(userID: userID, activityID: activity.id, modelContext: modelContext)
            let comments = try getComments(activityID: activity.id, modelContext: modelContext)
            
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

