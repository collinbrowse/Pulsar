//
//  DesignSystemTests.swift
//  PulsarTests
//
//  Tests for Design System components
//

import Testing
import SwiftUI
import Foundation
@testable import Pulsar

@Suite("Design System Tests")
struct DesignSystemTests {
    
    // MARK: - Activity Type Tests
    
    @Suite("Activity Type")
    struct ActivityTypeTests {
        
        @Test("Activity type display names")
        func testDisplayNames() async throws {
            #expect(ActivityType.run.displayName == "Run")
            #expect(ActivityType.ride.displayName == "Ride")
            #expect(ActivityType.swim.displayName == "Swim")
            #expect(ActivityType.hike.displayName == "Hike")
            #expect(ActivityType.walk.displayName == "Walk")
            #expect(ActivityType.workout.displayName == "Workout")
            #expect(ActivityType.other.displayName == "Activity")
        }
        
        @Test("Activity type icons")
        func testIcons() async throws {
            #expect(ActivityType.run.icon == "figure.run")
            #expect(ActivityType.ride.icon == "figure.outdoor.cycle")
            #expect(ActivityType.swim.icon == "figure.pool.swim")
            #expect(ActivityType.hike.icon == "figure.hiking")
            #expect(ActivityType.walk.icon == "figure.walk")
        }
        
        @Test("Activity type raw values")
        func testRawValues() async throws {
            #expect(ActivityType.run.rawValue == "run")
            #expect(ActivityType.ride.rawValue == "ride")
            #expect(ActivityType.swim.rawValue == "swim")
        }
        
        @Test("Activity type from raw value")
        func testFromRawValue() async throws {
            #expect(ActivityType(rawValue: "run") == .run)
            #expect(ActivityType(rawValue: "ride") == .ride)
            #expect(ActivityType(rawValue: "invalid") == nil)
        }
        
        @Test("All activity types are covered")
        func testAllCases() async throws {
            let allCases = ActivityType.allCases
            #expect(allCases.count == 7)
            #expect(allCases.contains(.run))
            #expect(allCases.contains(.ride))
            #expect(allCases.contains(.swim))
            #expect(allCases.contains(.hike))
            #expect(allCases.contains(.walk))
            #expect(allCases.contains(.workout))
            #expect(allCases.contains(.other))
        }
    }
    
    // MARK: - Visibility Tests
    
    @Suite("Visibility")
    struct VisibilityTests {
        
        @Test("Visibility display names")
        func testDisplayNames() async throws {
            #expect(Visibility.publicVisible.displayName == "Public")
            #expect(Visibility.followers.displayName == "Followers Only")
            #expect(Visibility.privateOnly.displayName == "Private")
        }
        
        @Test("Visibility icons")
        func testIcons() async throws {
            #expect(Visibility.publicVisible.icon == "globe")
            #expect(Visibility.followers.icon == "person.2")
            #expect(Visibility.privateOnly.icon == "lock")
        }
        
        @Test("Visibility raw values")
        func testRawValues() async throws {
            #expect(Visibility.publicVisible.rawValue == "public")
            #expect(Visibility.followers.rawValue == "followers")
            #expect(Visibility.privateOnly.rawValue == "private")
        }
    }
    
    // MARK: - Gender Tests
    
    @Suite("Gender")
    struct GenderTests {
        
        @Test("Gender display names")
        func testDisplayNames() async throws {
            #expect(Gender.male.displayName == "Male")
            #expect(Gender.female.displayName == "Female")
            #expect(Gender.nonBinary.displayName == "Non-binary")
            #expect(Gender.preferNotToSay.displayName == "Prefer not to say")
        }
        
        @Test("Gender raw values")
        func testRawValues() async throws {
            #expect(Gender.male.rawValue == "male")
            #expect(Gender.female.rawValue == "female")
            #expect(Gender.nonBinary.rawValue == "non_binary")
            #expect(Gender.preferNotToSay.rawValue == "prefer_not_to_say")
        }
    }
    
    // MARK: - Follow Status Tests
    
    @Suite("Follow Status")
    struct FollowStatusTests {
        
        @Test("Follow status raw values")
        func testRawValues() async throws {
            #expect(FollowStatus.pending.rawValue == "pending")
            #expect(FollowStatus.accepted.rawValue == "accepted")
            #expect(FollowStatus.blocked.rawValue == "blocked")
        }
    }
    
    // MARK: - Spacing Tests
    
    @Suite("Spacing")
    struct SpacingTests {
        
        @Test("Spacing values")
        func testSpacingValues() async throws {
            #expect(Spacing.xxs == 4)
            #expect(Spacing.xs == 8)
            #expect(Spacing.sm == 12)
            #expect(Spacing.md == 16)
            #expect(Spacing.lg == 20)
            #expect(Spacing.xl == 24)
            #expect(Spacing.xxl == 32)
            #expect(Spacing.xxxl == 48)
        }
    }
    
    // MARK: - Corner Radius Tests
    
    @Suite("Corner Radius")
    struct CornerRadiusTests {
        
        @Test("Corner radius values")
        func testCornerRadiusValues() async throws {
            #expect(CornerRadius.small == 8)
            #expect(CornerRadius.medium == 12)
            #expect(CornerRadius.large == 16)
            #expect(CornerRadius.xlarge == 24)
            #expect(CornerRadius.pill == 100)
        }
    }
    
    // MARK: - Coordinate Tests
    
    @Suite("Coordinate")
    struct CoordinateTests {
        
        @Test("Coordinate initialization")
        func testInitialization() async throws {
            let coord = Coordinate(latitude: 37.7749, longitude: -122.4194)
            
            #expect(coord.latitude == 37.7749)
            #expect(coord.longitude == -122.4194)
        }
        
        @Test("Coordinate encoding/decoding")
        func testCodable() async throws {
            let coord = Coordinate(latitude: 37.7749, longitude: -122.4194)
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(coord)
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Coordinate.self, from: data)
            
            #expect(decoded.latitude == coord.latitude)
            #expect(decoded.longitude == coord.longitude)
        }
        
        @Test("Coordinate hashable")
        func testHashable() async throws {
            let coord1 = Coordinate(latitude: 37.7749, longitude: -122.4194)
            let coord2 = Coordinate(latitude: 37.7749, longitude: -122.4194)
            let coord3 = Coordinate(latitude: 37.7750, longitude: -122.4194)
            
            #expect(coord1 == coord2)
            #expect(coord1 != coord3)
            
            var set = Set<Coordinate>()
            set.insert(coord1)
            set.insert(coord2)
            
            #expect(set.count == 1)
        }
    }
}
