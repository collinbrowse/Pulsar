//
//  FeedFlow.swift
//  Pulsar
//
//  Pure helpers for feed behavior so we can test
//  how the feed mutates without depending on SwiftUI.
//

import Foundation

enum FeedFlow {
    /// Toggles kudos for a specific activity and adjusts its kudos count.
    /// - Returns: A new array with the updated activity if found.
    static func toggleKudos(
        activities: [ActivityData],
        for activityId: UUID
    ) -> [ActivityData] {
        var updated = activities
        guard let index = updated.firstIndex(where: { $0.id == activityId }) else {
            return activities
        }
        
        var activity = updated[index]
        let wasKudos = activity.hasKudos
        activity.hasKudos.toggle()
        
        if activity.hasKudos {
            activity.kudosCount += 1
        } else if activity.kudosCount > 0 {
            activity.kudosCount -= 1
        }
        
        // Preserve immutability of ActivityData by reassigning into array.
        updated[index] = activity
        return updated
    }
}
