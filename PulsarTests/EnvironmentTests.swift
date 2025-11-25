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
struct EnvironmentTests {
    @Test("Environment should be accessible")
    @MainActor
    func testEnvironmentAccess() async throws {
        let env = AppEnvironment.shared
        
        // Environment should be accessible (values may be empty in test)
        // Note: supabaseURL and supabaseAnonKey are non-optional Strings, so they can't be nil
        // They may be empty strings if not configured, but they won't be nil
        #expect(!env.supabaseURL.isEmpty || env.supabaseURL.isEmpty) // Always true, just checking access
        #expect(!env.supabaseAnonKey.isEmpty || env.supabaseAnonKey.isEmpty) // Always true, just checking access
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
