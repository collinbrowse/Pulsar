//
//  ProfileAnalyticsTests.swift
//  PulsarTests
//
//  Tests for profile filtering and aggregate statistics.
//

import Foundation
@testable import Pulsar
import Testing

@Suite("Profile Analytics Tests")
struct ProfileAnalyticsTests {
    @Test("Filter activities by type when provided")
    func testFilterByType() async throws {
        let run = makeActivity(type: .run, distance: 1000)
        let ride = makeActivity(type: .ride, distance: 2000)
        
        let filtered = ProfileAnalytics.filteredActivities([run, ride], type: .run)
        #expect(filtered.count == 1)
        #expect(filtered.first?.type == .run)
    }
    
    @Test("Filter activities returns all when type is nil")
    func testFilterAllWhenNoType() async throws {
        let run = makeActivity(type: .run, distance: 1000)
        let ride = makeActivity(type: .ride, distance: 2000)
        
        let filtered = ProfileAnalytics.filteredActivities([run, ride], type: nil)
        #expect(filtered.count == 2)
    }
    
    @Test("Totals compute distance, time, and elevation correctly")
    func testTotals() async throws {
        let first = makeActivity(type: .run, distance: 1000, duration: 600, elevation: 10)
        let second = makeActivity(type: .run, distance: 2000, duration: 900, elevation: 20)
        let activities = [first, second]
        
        #expect(ProfileAnalytics.totalDistance(for: activities) == 3000)
        #expect(ProfileAnalytics.totalTime(for: activities) == 1500)
        #expect(ProfileAnalytics.totalElevation(for: activities) == 30)
    }
    
    // MARK: - Helper
    
    private func makeActivity(
        type: ActivityType,
        distance: Double,
        duration: Int = 600,
        elevation: Double? = nil
    ) -> ActivityData {
        ActivityData(
            id: UUID(),
            name: "Test",
            type: type,
            userName: "User",
            userAvatarURL: nil,
            distanceMeters: distance,
            durationSeconds: duration,
            elevationGainMeters: elevation,
            paceSecondsPerKm: nil,
            startDate: Date(),
            routeCoordinates: [],
            kudosCount: 0,
            commentsCount: 0,
            hasKudos: false
        )
    }
}
