//
//  AppStateTests.swift
//  PulsarTests
//
//  Created on 10/27/25.
//

import Foundation
@testable import Pulsar
import Testing

@Suite("App State Tests")
struct AppStateTests {
    @Test("Initial app state should be unauthenticated")
    @MainActor
    func testInitialState() async throws {
        let state = AppState()
        
        #expect(state.isAuthenticated == false)
        #expect(state.currentUserId == nil)
        #expect(state.userProfile == nil)
    }
    
    @Test("App state should report configuration status")
    @MainActor
    func testConfigurationStatus() async throws {
        let state = AppState()
        let env = AppEnvironment.shared
        
        // Configuration status should match environment
        #expect(state.isConfigured == env.isConfigured)
    }
}
