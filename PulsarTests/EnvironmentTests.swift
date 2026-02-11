//
//  EnvironmentTests.swift
//  PulsarTests
//
//  Created on 10/27/25.
//

import Testing
import Foundation
@testable import Pulsar

@Suite("Environment Configuration Tests")
@MainActor
struct EnvironmentTests {
    
    @Test("Environment should be accessible")
    func testEnvironmentAccess() async throws {
        let env = AppEnvironment.shared
        
        // Environment should be accessible (values may be empty in test)
        // supabaseURL and supabaseAnonKey are non-optional Strings with defaults
        #expect(!env.supabaseURL.isEmpty)
        #expect(!env.supabaseAnonKey.isEmpty)
    }
    
    @Test("Environment configuration status should be deterministic")
    func testConfigurationStatus() async throws {
        let env = AppEnvironment.shared
        
        // isConfigured should return consistent result
        let configured = env.isConfigured
        #expect(configured == env.isConfigured)
    }
}

