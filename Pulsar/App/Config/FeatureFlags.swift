//
//  FeatureFlags.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import Foundation

/// Feature flag management for gradual rollout and A/B testing
@MainActor
final class FeatureFlags {
    static let shared = FeatureFlags()
    
    // MARK: - Analytics & Observability
    
    var enableAnalytics: Bool {
        getFlag("ENABLE_ANALYTICS", default: false)
    }
    
    var enableCrashlytics: Bool {
        getFlag("ENABLE_CRASHLYTICS", default: false)
    }
    
    // MARK: - Maps
    
    var useMapbox: Bool {
        getFlag("USE_MAPBOX", default: false)
    }
    
    // MARK: - Premium Features
    
    var premiumAnalyticsEnabled: Bool {
        // Would check user entitlements in production
        true
    }
    
    // MARK: - Private Helpers
    
    private init() {}
    
    private func getFlag(_ key: String, default defaultValue: Bool) -> Bool {
        if let value = ProcessInfo.processInfo.environment[key] {
            return value.lowercased() == "true" || value == "1"
        }
        return defaultValue
    }
}
