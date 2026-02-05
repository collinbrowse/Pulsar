//
//  AppStateTests.swift
//  PulsarTests
//
//  Tests for AppState
//

import Foundation
@testable import Pulsar
import Testing

@Suite("App State Tests")
@MainActor
struct AppStateTests {
    @Test("Initial app state should be unauthenticated")
    func testInitialState() async throws {
        let state = AppState()
        
        #expect(state.isAuthenticated == false)
        #expect(state.currentUserID == nil)
        #expect(state.accessToken == nil)
        #expect(state.userProfile == nil)
        #expect(state.isLoading == false)
        #expect(state.errorMessage == nil)
        #expect(state.showError == false)
    }
    
    @Test("App state should report configuration status")
    func testConfigurationStatus() async throws {
        let state = AppState()
        
        // Configuration status should match environment
        #expect(state.isConfigured == AppEnvironment.shared.isConfigured)
    }
    
    @Test("Setting authenticated state")
    func testSetAuthenticated() async throws {
        let state = AppState()
        
        let profile = UserProfile(
            userID: "user-123",
            username: "athlete",
            fullName: "Test User",
            avatarURL: nil
        )
        
        state.setAuthenticated(
            userId: "user-123",
            accessToken: "jwt-token",
            profile: profile
        )
        
        #expect(state.isAuthenticated == true)
        #expect(state.currentUserID == "user-123")
        #expect(state.accessToken == "jwt-token")
        #expect(state.userProfile?.username == "athlete")
    }
    
    @Test("Sign out clears state")
    func testSignOut() async throws {
        let state = AppState()
        
        // First authenticate
        state.setAuthenticated(
            userId: "user-456",
            accessToken: "token",
            profile: nil
        )
        
        #expect(state.isAuthenticated == true)
        
        // Then sign out
        state.signOut()
        
        #expect(state.isAuthenticated == false)
        #expect(state.currentUserID == nil)
        #expect(state.accessToken == nil)
        #expect(state.userProfile == nil)
    }
    
    @Test("Show error sets message and flag")
    func testShowError() async throws {
        let state = AppState()
        
        state.showError("Test error message")
        
        #expect(state.errorMessage == "Test error message")
        #expect(state.showError == true)
    }
    
    @Test("User profile display name preference")
    func testUserProfileDisplayName() async throws {
        let profileWithFullName = UserProfile(
            userID: "1",
            username: "user1",
            fullName: "John Doe",
            avatarURL: nil
        )
        
        let profileWithoutFullName = UserProfile(
            userID: "2",
            username: "athlete123",
            fullName: nil,
            avatarURL: nil
        )
        
        #expect(profileWithFullName.displayName == "John Doe")
        #expect(profileWithoutFullName.displayName == "athlete123")
    }
    
    @Test("User profile equatable")
    func testUserProfileEquatable() async throws {
        let profile1 = UserProfile(
            userID: "1",
            username: "test",
            fullName: "Test",
            avatarURL: nil
        )
        
        let profile2 = UserProfile(
            userID: "1",
            username: "test",
            fullName: "Test",
            avatarURL: nil
        )
        
        let profile3 = UserProfile(
            userID: "2",
            username: "other",
            fullName: nil,
            avatarURL: nil
        )
        
        #expect(profile1 == profile2)
        #expect(profile1 != profile3)
    }
}
