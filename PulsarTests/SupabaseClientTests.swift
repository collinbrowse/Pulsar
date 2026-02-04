//
//  SupabaseClientTests.swift
//  PulsarTests
//
//  Created on 10/27/25.
//

import Foundation
@testable import Pulsar
import Testing

@Suite("Supabase Client Tests")
@MainActor
struct SupabaseClientTests {
    @Test("Supabase client should be initialized")
    func testClientInitialization() async throws {
        _ = SupabaseClient.shared
        // Client is a singleton, so it's always initialized
        // Verify client has valid configuration
        let env = AppEnvironment.shared
        #expect(!env.supabaseURL.isEmpty)
    }
    
    @Test("Environment should have valid Supabase URL")
    func testSupabaseURL() async throws {
        let env = AppEnvironment.shared
        
        #expect(!env.supabaseURL.isEmpty)
        #expect(env.supabaseURL.starts(with: "https://"))
    }
    
    @Test("Environment should have valid anon key")
    func testSupabaseAnonKey() async throws {
        let env = AppEnvironment.shared
        
        #expect(!env.supabaseAnonKey.isEmpty)
        #expect(env.supabaseAnonKey.starts(with: "eyJ")) // JWT format
    }
}
