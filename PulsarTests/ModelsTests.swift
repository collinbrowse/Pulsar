//
//  ModelsTests.swift
//  PulsarTests
//
//  Tests for SwiftData models
//

import Testing
import Foundation
import SwiftData
@testable import Pulsar

@Suite("Models Tests")
struct ModelsTests {
    
    // MARK: - Profile Tests
    
    @Suite("Profile Model")
    struct ProfileTests {
        
        @Test("Profile initialization with required fields")
        func testProfileInitialization() async throws {
            let profile = Profile(
                userId: "user-123",
                username: "athlete"
            )
            
            #expect(profile.userId == "user-123")
            #expect(profile.username == "athlete")
            #expect(profile.fullName == nil)
            #expect(profile.avatarURL == nil)
            #expect(profile.isPrivate == false)
            #expect(profile.totalActivities == 0)
            #expect(profile.totalDistanceMeters == 0)
        }
        
        @Test("Profile initialization with all fields")
        func testProfileFullInitialization() async throws {
            let profile = Profile(
                userId: "user-456",
                username: "runner_pro",
                fullName: "John Doe",
                bio: "Love running marathons",
                gender: .male,
                weightKg: 75.0,
                birthYear: 1990,
                location: "San Francisco, CA",
                isPrivate: true
            )
            
            #expect(profile.fullName == "John Doe")
            #expect(profile.gender == .male)
            #expect(profile.weightKg == 75.0)
            #expect(profile.birthYear == 1990)
            #expect(profile.isPrivate == true)
        }
        
        @Test("Profile display name fallback")
        func testProfileDisplayName() async throws {
            let profileWithName = Profile(userId: "1", username: "test", fullName: "Jane Doe")
            let profileWithoutName = Profile(userId: "2", username: "athlete123")
            
            #expect(profileWithName.displayName == "Jane Doe")
            #expect(profileWithoutName.displayName == "athlete123")
        }
        
        @Test("Profile age calculation")
        func testProfileAge() async throws {
            let currentYear = Calendar.current.component(.year, from: Date())
            let profile = Profile(userId: "1", username: "test", birthYear: 1990)
            
            let expectedAge = currentYear - 1990
            #expect(profile.age == expectedAge)
        }
        
        @Test("Profile age returns nil when birth year not set")
        func testProfileAgeNil() async throws {
            let profile = Profile(userId: "1", username: "test")
            
            #expect(profile.age == nil)
        }
    }
    
    // MARK: - Activity Tests
    
    @Suite("Activity Model")
    struct ActivityTests {
        
        @Test("Activity initialization")
        func testActivityInitialization() async throws {
            let activity = Activity(
                name: "Morning Run",
                activityType: .run,
                startDate: Date(),
                elapsedTimeSeconds: 1800,
                distanceMeters: 5000
            )
            
            #expect(activity.name == "Morning Run")
            #expect(activity.type == .run)
            #expect(activity.elapsedTimeSeconds == 1800)
            #expect(activity.distanceMeters == 5000)
            #expect(activity.visibility == .publicVisible)
            #expect(activity.kudosCount == 0)
            #expect(activity.commentsCount == 0)
        }
        
        @Test("Activity formatted distance")
        func testFormattedDistance() async throws {
            let activity = Activity(
                name: "Test",
                activityType: .run,
                startDate: Date(),
                elapsedTimeSeconds: 0,
                distanceMeters: 5432
            )
            
            #expect(activity.formattedDistance == "5.43 km")
        }
        
        @Test("Activity formatted duration - minutes only")
        func testFormattedDurationMinutes() async throws {
            let activity = Activity(
                name: "Test",
                activityType: .run,
                startDate: Date(),
                elapsedTimeSeconds: 1830, // 30:30
                distanceMeters: 5000
            )
            
            #expect(activity.formattedDuration == "30:30")
        }
        
        @Test("Activity formatted duration - with hours")
        func testFormattedDurationHours() async throws {
            let activity = Activity(
                name: "Test",
                activityType: .run,
                startDate: Date(),
                elapsedTimeSeconds: 3723, // 1:02:03
                distanceMeters: 5000
            )
            
            #expect(activity.formattedDuration == "1:02:03")
        }
        
        @Test("Activity formatted pace")
        func testFormattedPace() async throws {
            let activity = Activity(
                name: "Test",
                activityType: .run,
                startDate: Date(),
                elapsedTimeSeconds: 1500, // 25 minutes
                distanceMeters: 5000 // 5km
            )
            
            // 1500s / 5km = 300s/km = 5:00 /km
            #expect(activity.formattedPace == "5:00 /km")
        }
        
        @Test("Activity type conversion")
        func testActivityTypeConversion() async throws {
            let runActivity = Activity(
                name: "Run",
                activityType: .run,
                startDate: Date(),
                elapsedTimeSeconds: 0,
                distanceMeters: 0
            )
            
            let rideActivity = Activity(
                name: "Ride",
                activityType: .ride,
                startDate: Date(),
                elapsedTimeSeconds: 0,
                distanceMeters: 0
            )
            
            #expect(runActivity.type == .run)
            #expect(rideActivity.type == .ride)
            #expect(runActivity.activityType == "run")
            #expect(rideActivity.activityType == "ride")
        }
        
        @Test("Activity coordinates encoding/decoding")
        func testCoordinatesEncodingDecoding() async throws {
            let activity = Activity(
                name: "Test",
                activityType: .run,
                startDate: Date(),
                elapsedTimeSeconds: 0,
                distanceMeters: 0
            )
            
            let testCoords = [
                Coordinate(latitude: 37.7749, longitude: -122.4194),
                Coordinate(latitude: 37.7750, longitude: -122.4195)
            ]
            
            activity.setCoordinates(testCoords)
            let decoded = activity.coordinates
            
            #expect(decoded.count == 2)
            #expect(decoded[0].latitude == 37.7749)
            #expect(decoded[0].longitude == -122.4194)
        }
    }
    
    // MARK: - Segment Tests
    
    @Suite("Segment Model")
    struct SegmentTests {
        
        @Test("Segment initialization")
        func testSegmentInitialization() async throws {
            let segment = Segment(
                name: "Golden Gate Run",
                activityType: .run,
                distanceMeters: 2743,
                startLatitude: 37.8199,
                startLongitude: -122.4783,
                endLatitude: 37.8324,
                endLongitude: -122.4795
            )
            
            #expect(segment.name == "Golden Gate Run")
            #expect(segment.type == .run)
            #expect(segment.distanceMeters == 2743)
            #expect(segment.isPrivate == false)
            #expect(segment.isHazardous == false)
            #expect(segment.effortCount == 0)
        }
        
        @Test("Segment formatted distance")
        func testFormattedDistance() async throws {
            let segment = Segment(
                name: "Test",
                activityType: .run,
                distanceMeters: 2500,
                startLatitude: 0,
                startLongitude: 0,
                endLatitude: 0,
                endLongitude: 0
            )
            
            #expect(segment.formattedDistance == "2.50 km")
        }
    }
    
    // MARK: - Segment Effort Tests
    
    @Suite("Segment Effort Model")
    struct SegmentEffortTests {
        
        @Test("Segment effort initialization")
        func testEffortInitialization() async throws {
            let effort = SegmentEffort(
                elapsedTimeSeconds: 342,
                startDate: Date(),
                isPR: true
            )
            
            #expect(effort.elapsedTimeSeconds == 342)
            #expect(effort.isPR == true)
        }
        
        @Test("Segment effort formatted time - minutes")
        func testFormattedTimeMinutes() async throws {
            let effort = SegmentEffort(
                elapsedTimeSeconds: 342, // 5:42
                startDate: Date()
            )
            
            #expect(effort.formattedTime == "5:42")
        }
        
        @Test("Segment effort formatted time - with hours")
        func testFormattedTimeHours() async throws {
            let effort = SegmentEffort(
                elapsedTimeSeconds: 3723, // 1:02:03
                startDate: Date()
            )
            
            #expect(effort.formattedTime == "1:02:03")
        }
    }
    
    // MARK: - Follow Tests
    
    @Suite("Follow Model")
    struct FollowTests {
        
        @Test("Follow initialization")
        func testFollowInitialization() async throws {
            let follow = Follow(
                followerId: "user-1",
                followingId: "user-2",
                status: .accepted
            )
            
            #expect(follow.followerId == "user-1")
            #expect(follow.followingId == "user-2")
            #expect(follow.status == .accepted)
            #expect(follow.followId == "user-1_user-2")
        }
    }
    
    // MARK: - Kudos Tests
    
    @Suite("Kudos Model")
    struct KudosTests {
        
        @Test("Kudos initialization")
        func testKudosInitialization() async throws {
            let kudos = Kudos(userId: "user-1", activityId: "activity-1")
            
            #expect(kudos.userId == "user-1")
            #expect(kudos.activityId == "activity-1")
            #expect(kudos.kudosId == "user-1_activity-1")
        }
    }
    
    // MARK: - Comment Tests
    
    @Suite("Comment Model")
    struct CommentTests {
        
        @Test("Comment initialization")
        func testCommentInitialization() async throws {
            let comment = Comment(
                userId: "user-1",
                activityId: "activity-1",
                content: "Great run!"
            )
            
            #expect(comment.userId == "user-1")
            #expect(comment.activityId == "activity-1")
            #expect(comment.content == "Great run!")
            #expect(comment.updatedAt == nil)
        }
    }
}
