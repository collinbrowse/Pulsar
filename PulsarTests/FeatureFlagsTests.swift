//
//  FeatureFlagsTests.swift
//  PulsarTests
//
//  Created on 10/27/25.
//

import Foundation
@testable import Pulsar
import Testing

@Suite("Feature Flags Tests", .serialized)
@MainActor
struct FeatureFlagsTests {
    @Test("Feature flags should default to disabled")
    @MainActor
    func testDefaultFlags() async throws {
        let flags = FeatureFlags.shared
        
        // Analytics and crashlytics should be disabled by default for safety
        #expect(flags.enableAnalytics == false)
        #expect(flags.enableCrashlytics == false)
        #expect(flags.useMapbox == false)
    }
    
    @Test("Premium analytics should be enabled")
    @MainActor
    func testPremiumFeatures() async throws {
        let flags = FeatureFlags.shared
        
        // Premium features should be available (will check entitlements later)
        #expect(flags.premiumAnalyticsEnabled == true)
    }
}
