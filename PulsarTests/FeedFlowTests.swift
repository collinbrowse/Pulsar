//
//  FeedFlowTests.swift
//  PulsarTests
//
//  Tests for feed behavior (kudos toggling).
//

import Foundation
@testable import Pulsar
import Testing

@Suite("Feed Flow Tests")
struct FeedFlowTests {
    @Test("Toggle kudos adds kudos when previously not liked")
    func testToggleKudosAdds() async throws {
        let id = UUID()
        let activity = ActivityData(
            id: id,
            name: "Test",
            type: .run,
            userName: "User",
            userAvatarURL: nil,
            distanceMeters: 1000,
            durationSeconds: 300,
            elevationGainMeters: nil,
            paceSecondsPerKm: nil,
            startDate: Date(),
            routeCoordinates: [],
            kudosCount: 0,
            commentsCount: 0,
            hasKudos: false
        )
        
        let updated = FeedFlow.toggleKudos(activities: [activity], for: id)
        #expect(updated.count == 1)
        #expect(updated[0].hasKudos == true)
        #expect(updated[0].kudosCount == 1)
    }
    
    @Test("Toggle kudos removes kudos when previously liked")
    func testToggleKudosRemoves() async throws {
        let id = UUID()
        let activity = ActivityData(
            id: id,
            name: "Test",
            type: .run,
            userName: "User",
            userAvatarURL: nil,
            distanceMeters: 1000,
            durationSeconds: 300,
            elevationGainMeters: nil,
            paceSecondsPerKm: nil,
            startDate: Date(),
            routeCoordinates: [],
            kudosCount: 2,
            commentsCount: 0,
            hasKudos: true
        )
        
        let updated = FeedFlow.toggleKudos(activities: [activity], for: id)
        #expect(updated[0].hasKudos == false)
        #expect(updated[0].kudosCount == 1)
    }
    
    @Test("Toggle kudos on missing activity returns original array")
    func testToggleKudosMissingActivity() async throws {
        let activity = ActivityData(
            id: UUID(),
            name: "Test",
            type: .run,
            userName: "User",
            userAvatarURL: nil,
            distanceMeters: 1000,
            durationSeconds: 300,
            elevationGainMeters: nil,
            paceSecondsPerKm: nil,
            startDate: Date(),
            routeCoordinates: [],
            kudosCount: 0,
            commentsCount: 0,
            hasKudos: false
        )
        
        let updated = FeedFlow.toggleKudos(activities: [activity], for: UUID())
        #expect(updated[0].kudosCount == 0)
        #expect(updated[0].hasKudos == false)
    }
}
