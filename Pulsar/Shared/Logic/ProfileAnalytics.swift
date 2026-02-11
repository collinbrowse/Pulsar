//
//  ProfileAnalytics.swift
//  Pulsar
//
//  Pure helpers for profile statistics and filtering so
//  behavior can be tested independently of SwiftUI.
//

import Foundation

enum ProfileAnalytics {
    /// Filters activities by optional activity type.
    /// Time range is intentionally not applied yet, matching current UI behavior.
    static func filteredActivities(
        _ activities: [ActivityData],
        type: ActivityType?
    ) -> [ActivityData] {
        guard let type else { return activities }
        return activities.filter { $0.type == type }
    }
    
    static func totalDistance(for activities: [ActivityData]) -> Double {
        activities.reduce(0) { $0 + $1.distanceMeters }
    }
    
    static func totalTime(for activities: [ActivityData]) -> Int {
        activities.reduce(0) { $0 + $1.durationSeconds }
    }
    
    static func totalElevation(for activities: [ActivityData]) -> Double {
        activities.compactMap { $0.elevationGainMeters }.reduce(0, +)
    }
}
