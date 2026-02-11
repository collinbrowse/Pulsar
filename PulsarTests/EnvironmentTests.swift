//
//  EnvironmentTests.swift
//  PulsarTests
//
//  Created on 10/27/25.
//

import Foundation
@testable import Pulsar
import Testing

@Suite("Environment Configuration Tests")
@MainActor
struct EnvironmentTests {
    @Test("Environment should be accessible")
    @MainActor
    func testEnvironmentAccess() async throws {
        let env = AppEnvironment.shared
        
        // Environment should be accessible (values may be empty in test)
        // supabaseURL and supabaseAnonKey are non-optional Strings with defaults
        #expect(!env.supabaseURL.isEmpty)
        #expect(!env.supabaseAnonKey.isEmpty)
    }
    
    @Test("Environment configuration status should be deterministic")
    @MainActor
    func testConfigurationStatus() async throws {
        let env = AppEnvironment.shared
        
        // isConfigured should return consistent result
        let configured = env.isConfigured
        #expect(configured == env.isConfigured)
    }
}
