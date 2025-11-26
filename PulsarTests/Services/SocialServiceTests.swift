//
//  SocialServiceTests.swift
//  PulsarTests
//
//  Created on 11/24/25.
//

// swiftlint:disable file_length
import Foundation
@testable import Pulsar
import SwiftData
import Testing

@Suite("SocialService Tests")
@MainActor
// swiftlint:disable:next type_body_length
struct SocialServiceTests {
    // MARK: - Test Setup
    
    private func createTestModelContext() -> ModelContext {
        let schema = Schema([
            Follow.self,
            Kudo.self,
            Comment.self,
            Activity.self,
            Profile.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
        return ModelContext(container)
    }
    
    // MARK: - Follow Tests
    
    @Test("SocialService should follow a user")
    func testFollowUser() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        try await service.followUser(
            followerId: "user1",
            followingId: "user2",
            modelContext: modelContext
        )
        
        let isFollowing = try service.isFollowing(
            followerId: "user1",
            followingId: "user2",
            modelContext: modelContext
        )
        
        #expect(isFollowing == true)
    }
    
    @Test("SocialService should not error when following already followed user")
    func testFollowAlreadyFollowingUser() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Follow once
        try await service.followUser(
            followerId: "user1",
            followingId: "user2",
            modelContext: modelContext
        )
        
        // Follow again - should not error
        try await service.followUser(
            followerId: "user1",
            followingId: "user2",
            modelContext: modelContext
        )
        
        // Should still be following
        let isFollowing = try service.isFollowing(
            followerId: "user1",
            followingId: "user2",
            modelContext: modelContext
        )
        
        #expect(isFollowing == true)
    }
    
    @Test("SocialService should unfollow a user")
    func testUnfollowUser() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Follow first
        try await service.followUser(
            followerId: "user1",
            followingId: "user2",
            modelContext: modelContext
        )
        
        // Unfollow
        try await service.unfollowUser(
            followerId: "user1",
            followingId: "user2",
            modelContext: modelContext
        )
        
        let isFollowing = try service.isFollowing(
            followerId: "user1",
            followingId: "user2",
            modelContext: modelContext
        )
        
        #expect(isFollowing == false)
    }
    
    @Test("SocialService should not error when unfollowing non-followed user")
    func testUnfollowNotFollowingUser() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Unfollow without following first - should not error
        try await service.unfollowUser(
            followerId: "user1",
            followingId: "user2",
            modelContext: modelContext
        )
        
        let isFollowing = try service.isFollowing(
            followerId: "user1",
            followingId: "user2",
            modelContext: modelContext
        )
        
        #expect(isFollowing == false)
    }
    
    @Test("SocialService should correctly check if user is following")
    func testIsFollowing() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Initially not following
        let initiallyFollowing = try service.isFollowing(
            followerId: "user1",
            followingId: "user2",
            modelContext: modelContext
        )
        #expect(initiallyFollowing == false)
        
        // Follow
        try await service.followUser(
            followerId: "user1",
            followingId: "user2",
            modelContext: modelContext
        )
        
        // Now should be following
        let afterFollowing = try service.isFollowing(
            followerId: "user1",
            followingId: "user2",
            modelContext: modelContext
        )
        #expect(afterFollowing == true)
    }
    
    @Test("SocialService should get follower count")
    func testGetFollowerCount() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Initially no followers
        let initialCount = try service.getFollowerCount(userId: "user2", modelContext: modelContext)
        #expect(initialCount == 0)
        
        // Add followers
        try await service.followUser(followerId: "user1", followingId: "user2", modelContext: modelContext)
        try await service.followUser(followerId: "user3", followingId: "user2", modelContext: modelContext)
        
        let followerCount = try service.getFollowerCount(userId: "user2", modelContext: modelContext)
        #expect(followerCount == 2)
    }
    
    @Test("SocialService should get following count")
    func testGetFollowingCount() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Initially not following anyone
        let initialCount = try service.getFollowingCount(userId: "user1", modelContext: modelContext)
        #expect(initialCount == 0)
        
        // Follow multiple users
        try await service.followUser(followerId: "user1", followingId: "user2", modelContext: modelContext)
        try await service.followUser(followerId: "user1", followingId: "user3", modelContext: modelContext)
        try await service.followUser(followerId: "user1", followingId: "user4", modelContext: modelContext)
        
        let followingCount = try service.getFollowingCount(userId: "user1", modelContext: modelContext)
        #expect(followingCount == 3)
    }
    
    // MARK: - Kudo Tests
    
    @Test("SocialService should give kudo to activity")
    func testGiveKudo() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        try await service.giveKudo(
            userId: "user1",
            activityId: "activity1",
            modelContext: modelContext
        )
        
        let hasKudoed = try service.hasKudoed(
            userId: "user1",
            activityId: "activity1",
            modelContext: modelContext
        )
        
        #expect(hasKudoed == true)
    }
    
    @Test("SocialService should not error when giving kudo to already kudoed activity")
    func testGiveKudoAlreadyKudoed() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Give kudo once
        try await service.giveKudo(
            userId: "user1",
            activityId: "activity1",
            modelContext: modelContext
        )
        
        // Give kudo again - should not error
        try await service.giveKudo(
            userId: "user1",
            activityId: "activity1",
            modelContext: modelContext
        )
        
        // Should still have kudoed
        let hasKudoed = try service.hasKudoed(
            userId: "user1",
            activityId: "activity1",
            modelContext: modelContext
        )
        
        #expect(hasKudoed == true)
    }
    
    @Test("SocialService should remove kudo from activity")
    func testRemoveKudo() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Give kudo first
        try await service.giveKudo(
            userId: "user1",
            activityId: "activity1",
            modelContext: modelContext
        )
        
        // Remove kudo
        try await service.removeKudo(
            userId: "user1",
            activityId: "activity1",
            modelContext: modelContext
        )
        
        let hasKudoed = try service.hasKudoed(
            userId: "user1",
            activityId: "activity1",
            modelContext: modelContext
        )
        
        #expect(hasKudoed == false)
    }
    
    @Test("SocialService should not error when removing kudo from non-kudoed activity")
    func testRemoveKudoNotKudoed() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Remove kudo without giving first - should not error
        try await service.removeKudo(
            userId: "user1",
            activityId: "activity1",
            modelContext: modelContext
        )
        
        let hasKudoed = try service.hasKudoed(
            userId: "user1",
            activityId: "activity1",
            modelContext: modelContext
        )
        
        #expect(hasKudoed == false)
    }
    
    @Test("SocialService should get kudo count for activity")
    func testGetKudoCount() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Initially no kudos
        let initialCount = try service.getKudoCount(activityId: "activity1", modelContext: modelContext)
        #expect(initialCount == 0)
        
        // Add kudos from multiple users
        try await service.giveKudo(userId: "user1", activityId: "activity1", modelContext: modelContext)
        try await service.giveKudo(userId: "user2", activityId: "activity1", modelContext: modelContext)
        try await service.giveKudo(userId: "user3", activityId: "activity1", modelContext: modelContext)
        
        let kudoCount = try service.getKudoCount(activityId: "activity1", modelContext: modelContext)
        #expect(kudoCount == 3)
    }
    
    @Test("SocialService should check if user has kudoed")
    func testHasKudoed() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Initially has not kudoed
        let initiallyKudoed = try service.hasKudoed(
            userId: "user1",
            activityId: "activity1",
            modelContext: modelContext
        )
        #expect(initiallyKudoed == false)
        
        // Give kudo
        try await service.giveKudo(
            userId: "user1",
            activityId: "activity1",
            modelContext: modelContext
        )
        
        // Now should have kudoed
        let afterKudo = try service.hasKudoed(
            userId: "user1",
            activityId: "activity1",
            modelContext: modelContext
        )
        #expect(afterKudo == true)
    }
    
    // MARK: - Comment Tests
    
    @Test("SocialService should add comment to activity")
    func testAddComment() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        try await service.addComment(
            userId: "user1",
            activityId: "activity1",
            text: "Great workout!",
            modelContext: modelContext
        )
        
        let comments = try service.getComments(activityId: "activity1", modelContext: modelContext)
        #expect(comments.count == 1)
        #expect(comments.first?.text == "Great workout!")
        #expect(comments.first?.userId == "user1")
    }
    
    @Test("SocialService should reject empty comment")
    func testAddEmptyComment() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        do {
            try await service.addComment(
                userId: "user1",
                activityId: "activity1",
                text: "   ",
                modelContext: modelContext
            )
            Issue.record("Should have thrown SocialServiceError.emptyComment")
        } catch let error as SocialServiceError {
            if case .emptyComment = error {
                #expect(true)
            } else {
                Issue.record("Expected emptyComment error, got: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    @Test("SocialService should get comments for activity")
    func testGetComments() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Add multiple comments
        try await service.addComment(
            userId: "user1",
            activityId: "activity1",
            text: "First comment",
            modelContext: modelContext
        )
        try await service.addComment(
            userId: "user2",
            activityId: "activity1",
            text: "Second comment",
            modelContext: modelContext
        )
        try await service.addComment(
            userId: "user3",
            activityId: "activity1",
            text: "Third comment",
            modelContext: modelContext
        )
        
        let comments = try service.getComments(activityId: "activity1", modelContext: modelContext)
        #expect(comments.count == 3)
        
        // Comments should be sorted by createdAt descending (newest first)
        if comments.count >= 2 {
            #expect(comments[0].createdAt >= comments[1].createdAt)
        }
    }
    
    @Test("SocialService should delete comment")
    func testDeleteComment() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Add comment
        try await service.addComment(
            userId: "user1",
            activityId: "activity1",
            text: "Test comment",
            modelContext: modelContext
        )
        
        let commentsBefore = try service.getComments(activityId: "activity1", modelContext: modelContext)
        #expect(commentsBefore.count == 1)
        
        let commentId = try #require(commentsBefore.first?.id)
        
        // Delete comment
        try await service.deleteComment(
            commentID: commentId,
            userId: "user1",
            modelContext: modelContext
        )
        
        let commentsAfter = try service.getComments(activityId: "activity1", modelContext: modelContext)
        #expect(commentsAfter.isEmpty)
    }
    
    @Test("SocialService should throw error when deleting non-existent comment")
    func testDeleteNonExistentComment() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        do {
            try await service.deleteComment(
                commentID: "nonexistent-id",
                userId: "user1",
                modelContext: modelContext
            )
            Issue.record("Should have thrown SocialServiceError.commentNotFound")
        } catch let error as SocialServiceError {
            if case .commentNotFound = error {
                #expect(true)
            } else {
                Issue.record("Expected commentNotFound error, got: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    @Test("SocialService should only delete user's own comments")
    func testDeleteOnlyOwnComments() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Add comment from user1
        try await service.addComment(
            userId: "user1",
            activityId: "activity1",
            text: "User1's comment",
            modelContext: modelContext
        )
        
        let comments = try service.getComments(activityId: "activity1", modelContext: modelContext)
        let commentId = try #require(comments.first?.id)
        
        // Try to delete as user2 - should fail
        do {
            try await service.deleteComment(
                commentID: commentId,
                userId: "user2",
                modelContext: modelContext
            )
            Issue.record("Should have thrown error when deleting another user's comment")
        } catch let error as SocialServiceError {
            #expect(error == .commentNotFound)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
        
        // Comment should still exist
        let commentsAfter = try service.getComments(activityId: "activity1", modelContext: modelContext)
        #expect(commentsAfter.count == 1)
    }
    
    // MARK: - Feed Tests
    
    @Test("SocialService should get empty feed when not following anyone")
    func testGetEmptyFeed() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        let feed = try service.getFeed(userId: "user1", modelContext: modelContext)
        #expect(feed.isEmpty)
    }
    
    @Test("SocialService should get feed items from followed users")
    func testGetFeedFromFollowedUsers() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Create activities from user2
        let activity1 = Activity(
            userId: "user2",
            name: "Activity 1",
            activityType: .run,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            distance: 5000,
            duration: 1800
        )
        activity1.isPrivate = false
        
        let activity2 = Activity(
            userId: "user2",
            name: "Activity 2",
            activityType: .ride,
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date().addingTimeInterval(-1800),
            distance: 10000,
            duration: 1800
        )
        activity2.isPrivate = false
        
        modelContext.insert(activity1)
        modelContext.insert(activity2)
        try modelContext.save()
        
        // Follow user2
        try await service.followUser(
            followerId: "user1",
            followingId: "user2",
            modelContext: modelContext
        )
        
        // Get feed
        let feed = try service.getFeed(userId: "user1", modelContext: modelContext)
        #expect(feed.count == 2)
        #expect(feed[0].activity.userId == "user2")
    }
    
    @Test("SocialService should exclude private activities from feed")
    func testFeedExcludesPrivateActivities() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Create public activity
        let publicActivity = Activity(
            userId: "user2",
            name: "Public Activity",
            activityType: .run,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            distance: 5000,
            duration: 1800
        )
        publicActivity.isPrivate = false
        
        // Create private activity
        let privateActivity = Activity(
            userId: "user2",
            name: "Private Activity",
            activityType: .run,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            distance: 3000,
            duration: 1200
        )
        privateActivity.isPrivate = true
        
        modelContext.insert(publicActivity)
        modelContext.insert(privateActivity)
        try modelContext.save()
        
        // Follow user2
        try await service.followUser(
            followerId: "user1",
            followingId: "user2",
            modelContext: modelContext
        )
        
        // Get feed - should only include public activity
        let feed = try service.getFeed(userId: "user1", modelContext: modelContext)
        #expect(feed.count == 1)
        #expect(feed[0].activity.name == "Public Activity")
    }
    
    @Test("SocialService should include kudo count in feed items")
    func testFeedIncludesKudoCount() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Create activity
        let activity = Activity(
            userId: "user2",
            name: "Test Activity",
            activityType: .run,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            distance: 5000,
            duration: 1800
        )
        activity.isPrivate = false
        modelContext.insert(activity)
        try modelContext.save()
        
        // Add kudos
        try await service.giveKudo(userId: "user3", activityId: activity.id, modelContext: modelContext)
        try await service.giveKudo(userId: "user4", activityId: activity.id, modelContext: modelContext)
        
        // Follow user2
        try await service.followUser(followerId: "user1", followingId: "user2", modelContext: modelContext)
        
        // Get feed
        let feed = try service.getFeed(userId: "user1", modelContext: modelContext)
        #expect(feed.count == 1)
        #expect(feed[0].kudosCount == 2)
    }
    
    @Test("SocialService should include comment count in feed items")
    func testFeedIncludesCommentCount() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Create activity
        let activity = Activity(
            userId: "user2",
            name: "Test Activity",
            activityType: .run,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            distance: 5000,
            duration: 1800
        )
        activity.isPrivate = false
        modelContext.insert(activity)
        try modelContext.save()
        
        // Add comments
        try await service.addComment(userId: "user3", activityId: activity.id, text: "Comment 1", modelContext: modelContext)
        try await service.addComment(userId: "user4", activityId: activity.id, text: "Comment 2", modelContext: modelContext)
        try await service.addComment(userId: "user5", activityId: activity.id, text: "Comment 3", modelContext: modelContext)
        
        // Follow user2
        try await service.followUser(followerId: "user1", followingId: "user2", modelContext: modelContext)
        
        // Get feed
        let feed = try service.getFeed(userId: "user1", modelContext: modelContext)
        #expect(feed.count == 1)
        #expect(feed[0].commentsCount == 3)
    }
    
    @Test("SocialService should limit feed to 50 items")
    func testFeedLimit() async throws {
        let service = SocialService.shared
        let modelContext = createTestModelContext()
        
        // Create 60 activities
        for index in 0..<60 {
            let activity = Activity(
                userId: "user2",
                name: "Activity \(index)",
                activityType: .run,
                startDate: Date().addingTimeInterval(TimeInterval(-index * 60)),
                endDate: Date().addingTimeInterval(TimeInterval(-index * 60 + 1800)),
                distance: 5000,
                duration: 1800
            )
            activity.isPrivate = false
            modelContext.insert(activity)
        }
        try modelContext.save()
        
        // Follow user2
        try await service.followUser(followerId: "user1", followingId: "user2", modelContext: modelContext)
        
        // Get feed - should be limited to 50
        let feed = try service.getFeed(userId: "user1", modelContext: modelContext)
        #expect(feed.count == 50)
    }
}
