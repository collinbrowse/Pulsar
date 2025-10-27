//
//  SupabaseClientTests.swift
//  PulsarTests
//
//  Created on 10/27/25.
//

import Testing
import Foundation
@testable import Pulsar

@Suite("Supabase Client Tests")
@MainActor
struct SupabaseClientTests {
    
    @Test("Supabase client should be initialized")
    func testClientInitialization() async throws {
        let client = SupabaseClient.shared
        
        #expect(client != nil)
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

