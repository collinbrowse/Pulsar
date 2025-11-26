//
//  SocialService.swift
//  Pulsar
//
//  Created on 10/27/25.
//

// swiftlint:disable file_length
import Foundation
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.collinbrowse.Pulsar", category: "SocialService")

/// Service for managing social interactions (follows, kudos, comments)
@MainActor
// swiftlint:disable:next type_body_length
final class SocialService {
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
        
        // Sync to backend
        do {
            let accessToken = try await AuthenticationService.shared.getValidAccessToken()
            let dto = follow.toDTO()
            try await SupabaseClient.shared.upsert(
                table: "follows",
                data: dto,
                accessToken: accessToken
            )
            logger.info("✅ Follow synced to backend")
        } catch {
            // Log error but don't fail - local save succeeded
            logger.error("❌ Failed to sync follow to backend: \(error.localizedDescription)")
        }
        
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
        guard let follow = follows.first else {
            logger.warning("No follow relationship found to unfollow")
            return
        }
        
        // Delete from backend first (before local delete)
        do {
            let accessToken = try await AuthenticationService.shared.getValidAccessToken()
            try await SupabaseClient.shared.delete(
                table: "follows",
                filter: ["id": follow.id],
                accessToken: accessToken
            )
            logger.info("✅ Follow deleted from backend")
        } catch {
            // Log error but continue with local delete
            logger.error("❌ Failed to delete follow from backend: \(error.localizedDescription)")
        }
        
        // Delete locally
        for follow in follows {
            modelContext.delete(follow)
        }
        try modelContext.save()
        
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
        
        // Sync to backend
        do {
            let accessToken = try await AuthenticationService.shared.getValidAccessToken()
            let dto = kudo.toDTO()
            try await SupabaseClient.shared.upsert(
                table: "kudos",
                data: dto,
                accessToken: accessToken
            )
            logger.info("✅ Kudo synced to backend")
        } catch {
            // Log error but don't fail - local save succeeded
            logger.error("❌ Failed to sync kudo to backend: \(error.localizedDescription)")
        }
        
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
        guard let kudo = kudos.first else {
            logger.warning("No kudo found to remove")
            return
        }
        
        // Delete from backend first (before local delete)
        do {
            let accessToken = try await AuthenticationService.shared.getValidAccessToken()
            try await SupabaseClient.shared.delete(
                table: "kudos",
                filter: ["id": kudo.id],
                accessToken: accessToken
            )
            logger.info("✅ Kudo deleted from backend")
        } catch {
            // Log error but continue with local delete
            logger.error("❌ Failed to delete kudo from backend: \(error.localizedDescription)")
        }
        
        // Delete locally
        for kudo in kudos {
            modelContext.delete(kudo)
        }
        try modelContext.save()
        
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
        
        // Sync to backend
        do {
            let accessToken = try await AuthenticationService.shared.getValidAccessToken()
            let dto = comment.toDTO()
            try await SupabaseClient.shared.upsert(
                table: "comments",
                data: dto,
                accessToken: accessToken
            )
            logger.info("✅ Comment synced to backend")
        } catch {
            // Log error but don't fail - local save succeeded
            logger.error("❌ Failed to sync comment to backend: \(error.localizedDescription)")
        }
        
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
        
        // Delete from backend first (before local delete)
        do {
            let accessToken = try await AuthenticationService.shared.getValidAccessToken()
            try await SupabaseClient.shared.delete(
                table: "comments",
                filter: ["id": comment.id],
                accessToken: accessToken
            )
            logger.info("✅ Comment deleted from backend")
        } catch {
            // Log error but continue with local delete
            logger.error("❌ Failed to delete comment from backend: \(error.localizedDescription)")
        }
        
        // Delete locally
        modelContext.delete(comment)
        try modelContext.save()
        
        logger.info("✅ Comment deleted successfully")
    }
    
    // MARK: - Backend Sync
    
    /// Sync follows from backend to local storage
    func syncFollowsFromBackend(
        for userId: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("🔄 Syncing follows from backend for user: \(userId)")
        
        let accessToken = try await AuthenticationService.shared.getValidAccessToken()
        
        // Fetch follows from backend where user is the follower
        let backendFollows: [FollowDTO] = try await SupabaseClient.shared.fetch(
            from: "follows",
            select: "id,follower_id,following_id,created_at",
            filter: ["follower_id": userId],
            accessToken: accessToken
        )
        
        logger.info("📥 Fetched \(backendFollows.count) follows from backend")
        
        // Get existing local follows
        let localFollows = try modelContext.fetch(
            FetchDescriptor<Follow>(
                predicate: #Predicate { follow in
                    follow.followerId == userId
                }
            )
        )
        let localFollowIDs = Set(localFollows.map { $0.id })
        
        // Merge backend follows with local data
        for dto in backendFollows {
            if localFollowIDs.contains(dto.id) {
                // Already exists locally, skip
                continue
            } else {
                // Create new follow from backend
                let follow = Follow.fromDTO(dto)
                modelContext.insert(follow)
                logger.debug("Inserted follow from backend: \(dto.id)")
            }
        }
        
        try modelContext.save()
        logger.info("✅ Follows synced from backend")
    }
    
    /// Sync kudos from backend to local storage
    func syncKudosFromBackend(
        for userId: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("🔄 Syncing kudos from backend for user: \(userId)")
        
        let accessToken = try await AuthenticationService.shared.getValidAccessToken()
        
        // Fetch kudos from backend for user's activities
        // First, get user's activity IDs
        let activityDescriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                activity.userId == userId
            }
        )
        let activities = try modelContext.fetch(activityDescriptor)
        let activityIDs = activities.map { $0.id }
        
        guard !activityIDs.isEmpty else {
            logger.info("No activities found, skipping kudo sync")
            return
        }
        
        // Fetch kudos for these activities
        var allKudos: [KudoDTO] = []
        for activityId in activityIDs {
            let kudos: [KudoDTO] = try await SupabaseClient.shared.fetch(
                from: "kudos",
                select: "id,user_id,activity_id,created_at",
                filter: ["activity_id": activityId],
                accessToken: accessToken
            )
            allKudos.append(contentsOf: kudos)
        }
        
        logger.info("📥 Fetched \(allKudos.count) kudos from backend")
        
        // Get existing local kudos
        let localKudos = try modelContext.fetch(
            FetchDescriptor<Kudo>(
                predicate: #Predicate { kudo in
                    activityIDs.contains(kudo.activityId)
                }
            )
        )
        let localKudoIDs = Set(localKudos.map { $0.id })
        
        // Merge backend kudos with local data
        for dto in allKudos {
            if localKudoIDs.contains(dto.id) {
                // Already exists locally, skip
                continue
            } else {
                // Create new kudo from backend
                let kudo = Kudo.fromDTO(dto)
                modelContext.insert(kudo)
                logger.debug("Inserted kudo from backend: \(dto.id)")
            }
        }
        
        try modelContext.save()
        logger.info("✅ Kudos synced from backend")
    }
    
    /// Sync comments from backend to local storage
    func syncCommentsFromBackend(
        for userId: String,
        modelContext: ModelContext
    ) async throws {
        logger.info("🔄 Syncing comments from backend for user: \(userId)")
        
        let accessToken = try await AuthenticationService.shared.getValidAccessToken()
        
        // Fetch comments from backend for user's activities
        // First, get user's activity IDs
        let activityDescriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { activity in
                activity.userId == userId
            }
        )
        let activities = try modelContext.fetch(activityDescriptor)
        let activityIDs = activities.map { $0.id }
        
        guard !activityIDs.isEmpty else {
            logger.info("No activities found, skipping comment sync")
            return
        }
        
        // Fetch comments for these activities
        var allComments: [CommentDTO] = []
        for activityId in activityIDs {
            let comments: [CommentDTO] = try await SupabaseClient.shared.fetch(
                from: "comments",
                select: "id,user_id,activity_id,text,created_at,updated_at",
                filter: ["activity_id": activityId],
                accessToken: accessToken
            )
            allComments.append(contentsOf: comments)
        }
        
        logger.info("📥 Fetched \(allComments.count) comments from backend")
        
        // Get existing local comments
        let localComments = try modelContext.fetch(
            FetchDescriptor<Comment>(
                predicate: #Predicate { comment in
                    activityIDs.contains(comment.activityId)
                }
            )
        )
        let localCommentIDs = Set(localComments.map { $0.id })
        
        // Merge backend comments with local data
        for dto in allComments {
            if localCommentIDs.contains(dto.id) {
                // Already exists locally, skip
                continue
            } else {
                // Create new comment from backend
                let comment = Comment.fromDTO(dto)
                modelContext.insert(comment)
                logger.debug("Inserted comment from backend: \(dto.id)")
            }
        }
        
        try modelContext.save()
        logger.info("✅ Comments synced from backend")
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
        
        // Fetch all profiles and create lookup map (predicates can't use captured variables)
        let activityUserIds = Set(activities.prefix(50).map { $0.userId })
        let allProfiles = try modelContext.fetch(FetchDescriptor<Profile>())
        let profileMap = Dictionary(
            uniqueKeysWithValues: allProfiles
                .filter { activityUserIds.contains($0.userId) }
                .map { ($0.userId, $0) }
        )
        
        // Build feed items
        var feedItems: [FeedItem] = []
        for activity in activities.prefix(50) { // Limit to 50 items
            // Use actual profile if found, otherwise create fallback placeholder
            let profile = profileMap[activity.userId] ?? Profile(
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
