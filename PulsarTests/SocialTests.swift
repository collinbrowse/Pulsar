//
//  SocialTests.swift
//  PulsarTests
//
//  Created on 10/27/25.
//

import Testing
import SwiftData
@testable import Pulsar

@Suite("Social Models Tests")
struct SocialModelsTests {
    
    @Test("Follow should initialize correctly")
    func testFollowInitialization() async throws {
        let follow = Follow(
            followerID: "user1",
            followingID: "user2"
        )
        
        #expect(follow.followerID == "user1")
        #expect(follow.followingID == "user2")
        #expect(!follow.id.isEmpty)
    }
    
    @Test("Kudo should initialize correctly")
    func testKudoInitialization() async throws {
        let kudo = Kudo(
            userID: "user1",
            activityID: "activity1"
        )
        
        #expect(kudo.userID == "user1")
        #expect(kudo.activityID == "activity1")
        #expect(!kudo.id.isEmpty)
    }
    
    @Test("Comment should initialize correctly")
    func testCommentInitialization() async throws {
        let comment = Comment(
            userID: "user1",
            activityID: "activity1",
            text: "Great workout!"
        )
        
        #expect(comment.userID == "user1")
        #expect(comment.activityID == "activity1")
        #expect(comment.text == "Great workout!")
        #expect(!comment.id.isEmpty)
    }
    
    @Test("Follow DTO conversion should preserve data")
    func testFollowDTOConversion() async throws {
        let follow = Follow(
            id: "follow1",
            followerID: "user1",
            followingID: "user2"
        )
        
        let dto = follow.toDTO()
        
        #expect(dto.id == "follow1")
        #expect(dto.followerId == "user1")
        #expect(dto.followingId == "user2")
        
        let reconstructed = Follow.fromDTO(dto)
        #expect(reconstructed.id == follow.id)
        #expect(reconstructed.followerID == follow.followerID)
    }
    
    @Test("Kudo DTO conversion should preserve data")
    func testKudoDTOConversion() async throws {
        let kudo = Kudo(
            id: "kudo1",
            userID: "user1",
            activityID: "activity1"
        )
        
        let dto = kudo.toDTO()
        
        #expect(dto.id == "kudo1")
        #expect(dto.userId == "user1")
        #expect(dto.activityId == "activity1")
        
        let reconstructed = Kudo.fromDTO(dto)
        #expect(reconstructed.id == kudo.id)
    }
    
    @Test("Comment DTO conversion should preserve data")
    func testCommentDTOConversion() async throws {
        let comment = Comment(
            id: "comment1",
            userID: "user1",
            activityID: "activity1",
            text: "Nice work!"
        )
        
        let dto = comment.toDTO()
        
        #expect(dto.id == "comment1")
        #expect(dto.userId == "user1")
        #expect(dto.activityId == "activity1")
        #expect(dto.text == "Nice work!")
        
        let reconstructed = Comment.fromDTO(dto)
        #expect(reconstructed.id == comment.id)
        #expect(reconstructed.text == comment.text)
    }
}

@Suite("Feed Item Tests")
struct FeedItemTests {
    
    @Test("Feed item should calculate time ago correctly")
    func testTimeAgoCalculation() async throws {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        
        let activity = Activity(
            userID: "user1",
            name: "Test Run",
            activityType: .run,
            startDate: oneHourAgo,
            endDate: now,
            distance: 5000,
            duration: 1800
        )
        
        let profile = Profile(
            userID: "user1",
            username: "testuser",
            email: "test@test.com"
        )
        
        let feedItem = FeedItem(
            id: "1",
            activity: activity,
            profile: profile,
            kudosCount: 5,
            commentsCount: 2,
            hasUserKudoed: false,
            recentComments: []
        )
        
        #expect(feedItem.timeAgo.contains("h"))
    }
}

@Suite("Social Service Tests")
struct SocialServiceTests {
    
    @Test("Social service error should have descriptive messages")
    func testErrorMessages() async throws {
        let emptyCommentError = SocialServiceError.emptyComment
        #expect(emptyCommentError.errorDescription?.contains("empty") == true)
        
        let notFoundError = SocialServiceError.commentNotFound
        #expect(notFoundError.errorDescription?.contains("not found") == true)
    }
}

