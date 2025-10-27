//
//  AppStateTests.swift
//  PulsarTests
//
//  Created on 10/27/25.
//

import Testing
import Foundation
@testable import Pulsar

@Suite("App State Tests")
struct AppStateTests {
    
    @Test("Initial app state should be unauthenticated")
    func testInitialState() async throws {
        let state = AppState()
        
        #expect(state.isAuthenticated == false)
        #expect(state.currentUserID == nil)
        #expect(state.userProfile == nil)
    }
    
    @Test("App state should report configuration status")
    func testConfigurationStatus() async throws {
        let state = AppState()
        
        // Configuration status should match environment
        #expect(state.isConfigured == AppEnvironment.shared.isConfigured)
    }
}

