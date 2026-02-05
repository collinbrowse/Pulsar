//
//  SettingsFlowTests.swift
//  PulsarTests
//
//  Tests for settings-related flows such as sign out and delete account.
//

import Foundation
@testable import Pulsar
import Testing

@Suite("Settings Flow Tests")
@MainActor
struct SettingsFlowTests {
    @Test("Sign out clears authentication state")
    func testSignOutClearsState() async throws {
        let state = AppState()
        state.setAuthenticated(
            userId: "user-123",
            accessToken: "token",
            profile: UserProfile(
                userID: "user-123",
                username: "athlete",
                fullName: "Test User",
                avatarURL: nil
            )
        )
        
        #expect(state.isAuthenticated == true)
        #expect(state.currentUserID == "user-123")
        #expect(state.userProfile != nil)
        
        SettingsFlow.signOut(appState: state)
        
        #expect(state.isAuthenticated == false)
        #expect(state.currentUserID == nil)
        #expect(state.userProfile == nil)
    }
    
    @Test("Delete account also clears authentication state")
    func testDeleteAccountClearsState() async throws {
        let state = AppState()
        state.setAuthenticated(
            userId: "user-456",
            accessToken: "token",
            profile: nil
        )
        
        SettingsFlow.deleteAccount(appState: state)
        
        #expect(state.isAuthenticated == false)
        #expect(state.currentUserID == nil)
    }
}
