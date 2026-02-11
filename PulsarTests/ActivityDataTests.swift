//
//  ActivityDataTests.swift
//  PulsarTests
//
//  Tests for ActivityData view model
//

import Testing
import Foundation
@testable import Pulsar

@Suite("Activity Data Tests")
@MainActor
struct ActivityDataTests {
    
    // MARK: - Formatting Tests
    
    @Suite("Formatting")
    @MainActor
    struct FormattingTests {
        
        @Test("Formatted distance - less than 1km")
        func testFormattedDistanceSmall() async throws {
            let activity = createActivity(distanceMeters: 500)
            #expect(activity.formattedDistance == "0.50")
        }
        
        @Test("Formatted distance - kilometers")
        func testFormattedDistanceKm() async throws {
            let activity = createActivity(distanceMeters: 5432)
            #expect(activity.formattedDistance == "5.43")
        }
        
        @Test("Formatted distance - long distance")
        func testFormattedDistanceLong() async throws {
            let activity = createActivity(distanceMeters: 42195)
            #expect(activity.formattedDistance == "42.20")
        }
        
        @Test("Formatted duration - under 1 hour")
        func testFormattedDurationMinutes() async throws {
            let activity = createActivity(durationSeconds: 1832) // 30:32
            #expect(activity.formattedDuration == "30:32")
        }
        
        @Test("Formatted duration - exactly 1 hour")
        func testFormattedDurationOneHour() async throws {
            let activity = createActivity(durationSeconds: 3600)
            #expect(activity.formattedDuration == "1:00:00")
        }
        
        @Test("Formatted duration - over 1 hour")
        func testFormattedDurationHours() async throws {
            let activity = createActivity(durationSeconds: 5432) // 1:30:32
            #expect(activity.formattedDuration == "1:30:32")
        }
        
        @Test("Formatted pace - fast pace")
        func testFormattedPaceFast() async throws {
            let activity = ActivityData(
                id: UUID(),
                name: "Test",
                type: .run,
                userName: "Test",
                userAvatarURL: nil,
                distanceMeters: 5000,
                durationSeconds: 1200, // 4:00/km
                elevationGainMeters: nil,
                paceSecondsPerKm: 240,
                startDate: Date(),
                routeCoordinates: [],
                kudosCount: 0,
                commentsCount: 0,
                hasKudos: false
            )
            
            #expect(activity.formattedPace == "4:00")
        }
        
        @Test("Formatted pace - slow pace")
        func testFormattedPaceSlow() async throws {
            let activity = ActivityData(
                id: UUID(),
                name: "Test",
                type: .run,
                userName: "Test",
                userAvatarURL: nil,
                distanceMeters: 5000,
                durationSeconds: 2400,
                elevationGainMeters: nil,
                paceSecondsPerKm: 480, // 8:00/km
                startDate: Date(),
                routeCoordinates: [],
                kudosCount: 0,
                commentsCount: 0,
                hasKudos: false
            )
            
            #expect(activity.formattedPace == "8:00")
        }
        
        @Test("Formatted pace - nil when not set")
        func testFormattedPaceNil() async throws {
            let activity = createActivity()
            #expect(activity.formattedPace == nil)
        }
        
        @Test("Formatted elevation")
        func testFormattedElevation() async throws {
            let activity = ActivityData(
                id: UUID(),
                name: "Test",
                type: .hike,
                userName: "Test",
                userAvatarURL: nil,
                distanceMeters: 10000,
                durationSeconds: 7200,
                elevationGainMeters: 567.8,
                paceSecondsPerKm: nil,
                startDate: Date(),
                routeCoordinates: [],
                kudosCount: 0,
                commentsCount: 0,
                hasKudos: false
            )
            
            #expect(activity.formattedElevation == "568")
        }
        
        @Test("Formatted elevation - nil when not set")
        func testFormattedElevationNil() async throws {
            let activity = createActivity()
            #expect(activity.formattedElevation == nil)
        }
    }
    
    // MARK: - Properties Tests
    
    @Suite("Properties")
    @MainActor
    struct PropertiesTests {
        
        @Test("Has route - with coordinates")
        func testHasRouteTrue() async throws {
            let activity = ActivityData(
                id: UUID(),
                name: "Test",
                type: .run,
                userName: "Test",
                userAvatarURL: nil,
                distanceMeters: 5000,
                durationSeconds: 1800,
                elevationGainMeters: nil,
                paceSecondsPerKm: nil,
                startDate: Date(),
                routeCoordinates: [
                    Coordinate(latitude: 37.7749, longitude: -122.4194),
                    Coordinate(latitude: 37.7750, longitude: -122.4195)
                ],
                kudosCount: 0,
                commentsCount: 0,
                hasKudos: false
            )
            
            #expect(activity.hasRoute == true)
        }
        
        @Test("Has route - without coordinates")
        func testHasRouteFalse() async throws {
            let activity = createActivity()
            #expect(activity.hasRoute == false)
        }
        
        @Test("Relative time")
        func testRelativeTime() async throws {
            let activity = ActivityData(
                id: UUID(),
                name: "Test",
                type: .run,
                userName: "Test",
                userAvatarURL: nil,
                distanceMeters: 5000,
                durationSeconds: 1800,
                elevationGainMeters: nil,
                paceSecondsPerKm: nil,
                startDate: Date().addingTimeInterval(-3600), // 1 hour ago
                routeCoordinates: [],
                kudosCount: 0,
                commentsCount: 0,
                hasKudos: false
            )
            
            // Should contain "hr" or "hour" for 1 hour ago
            let relativeTime = activity.relativeTime
            #expect(!relativeTime.isEmpty)
        }
    }
    
    // MARK: - Helper
    
    private static func createActivity(
        distanceMeters: Double = 5000,
        durationSeconds: Int = 1800
    ) -> ActivityData {
        ActivityData(
            id: UUID(),
            name: "Test Activity",
            type: .run,
            userName: "Test User",
            userAvatarURL: nil,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
            elevationGainMeters: nil,
            paceSecondsPerKm: nil,
            startDate: Date(),
            routeCoordinates: [],
            kudosCount: 0,
            commentsCount: 0,
            hasKudos: false
        )
    }
}

// MARK: - Time Range Tests

@Suite("Time Range Tests")
@MainActor
struct TimeRangeTests {
    
    @Test("Time range display names")
    func testDisplayNames() async throws {
        #expect(TimeRange.week.displayName == "This Week")
        #expect(TimeRange.month.displayName == "This Month")
        #expect(TimeRange.year.displayName == "This Year")
        #expect(TimeRange.allTime.displayName == "All Time")
    }
    
    @Test("Time range raw values")
    func testRawValues() async throws {
        #expect(TimeRange.week.rawValue == "week")
        #expect(TimeRange.month.rawValue == "month")
        #expect(TimeRange.year.rawValue == "year")
        #expect(TimeRange.allTime.rawValue == "all")
    }
    
    @Test("All time ranges covered")
    func testAllCases() async throws {
        let allCases = TimeRange.allCases
        #expect(allCases.count == 4)
    }
}

// MARK: - Units Tests

@Suite("Units Tests")
@MainActor
struct UnitsTests {
    
    @Suite("Distance Unit")
    @MainActor
    struct DistanceUnitTests {
        
        @Test("Distance unit display names")
        func testDisplayNames() async throws {
            #expect(DistanceUnit.kilometers.displayName == "Kilometers")
            #expect(DistanceUnit.miles.displayName == "Miles")
        }
        
        @Test("Distance unit raw values")
        func testRawValues() async throws {
            #expect(DistanceUnit.kilometers.rawValue == "km")
            #expect(DistanceUnit.miles.rawValue == "mi")
        }
    }
    
    @Suite("Pace Unit")
    @MainActor
    struct PaceUnitTests {
        
        @Test("Pace unit display names")
        func testDisplayNames() async throws {
            #expect(PaceUnit.minPerKm.displayName == "min/km")
            #expect(PaceUnit.minPerMile.displayName == "min/mi")
        }
        
        @Test("Pace unit raw values")
        func testRawValues() async throws {
            #expect(PaceUnit.minPerKm.rawValue == "min/km")
            #expect(PaceUnit.minPerMile.rawValue == "min/mi")
        }
    }
}

// MARK: - Leaderboard Filter Tests

@Suite("Leaderboard Filter Tests")
@MainActor
struct LeaderboardFilterTests {
    
    @Test("Filter titles")
    func testTitles() async throws {
        #expect(LeaderboardFilter.overall.title == "Overall")
        #expect(LeaderboardFilter.thisYear.title == "This Year")
        #expect(LeaderboardFilter.female.title == "Women")
        #expect(LeaderboardFilter.male.title == "Men")
        #expect(LeaderboardFilter.following.title == "Following")
    }
    
    @Test("All filters covered")
    func testAllCases() async throws {
        let allCases = LeaderboardFilter.allCases
        #expect(allCases.count == 5)
    }
}

// MARK: - Tab Tests

@Suite("Tab Tests")
@MainActor
struct TabTests {
    
    @Test("Tab titles")
    func testTitles() async throws {
        #expect(Tab.feed.title == "Feed")
        #expect(Tab.segments.title == "Segments")
        #expect(Tab.record.title == "Import")
        #expect(Tab.profile.title == "Profile")
        #expect(Tab.settings.title == "Settings")
    }
    
    @Test("Tab icons")
    func testIcons() async throws {
        #expect(Tab.feed.icon == "rectangle.stack")
        #expect(Tab.segments.icon == "flag")
        #expect(Tab.record.icon == "plus.circle")
        #expect(Tab.profile.icon == "person")
        #expect(Tab.settings.icon == "gearshape")
    }
    
    @Test("Tab selected icons")
    func testSelectedIcons() async throws {
        #expect(Tab.feed.selectedIcon == "rectangle.stack.fill")
        #expect(Tab.segments.selectedIcon == "flag.fill")
        #expect(Tab.profile.selectedIcon == "person.fill")
        #expect(Tab.settings.selectedIcon == "gearshape.fill")
    }
    
    @Test("All tabs covered")
    func testAllCases() async throws {
        let allCases = Tab.allCases
        #expect(allCases.count == 5)
    }
}
