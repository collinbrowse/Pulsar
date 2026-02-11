//
//  NetworkingTests.swift
//  PulsarTests
//
//  Tests for networking layer
//

import Testing
import Foundation
@testable import Pulsar

@Suite("Networking Tests")
struct NetworkingTests {
    
    // MARK: - Network Error Tests
    
    @Suite("Network Error")
    struct NetworkErrorTests {
        
        @Test("Error descriptions")
        func testErrorDescriptions() async throws {
            #expect(NetworkError.invalidResponse.errorDescription == "Invalid server response")
            #expect(NetworkError.invalidData.errorDescription == "Invalid data received")
            #expect(NetworkError.httpError(statusCode: 404, serverMessage: nil).errorDescription == "HTTP error: 404")
            #expect(NetworkError.httpError(statusCode: 500, serverMessage: nil).errorDescription == "HTTP error: 500")
            #expect(NetworkError.unauthorized.errorDescription == "Authentication required")
        }
        
        @Test("HTTP error uses server message when present")
        func testHttpErrorServerMessage() async throws {
            let msg = "This email is already registered."
            #expect(NetworkError.httpError(statusCode: 422, serverMessage: msg).errorDescription == msg)
        }
        
        @Test("Error localized description")
        func testLocalizedDescription() async throws {
            let error: NetworkError = .httpError(statusCode: 403, serverMessage: nil)
            #expect(error.localizedDescription.contains("403"))
        }
    }
    
    // MARK: - User Model Tests
    
    @Suite("User Model")
    struct UserModelTests {
        
        @Test("User initialization")
        func testUserInitialization() async throws {
            let user = User(id: "user-123", email: "test@example.com")
            
            #expect(user.id == "user-123")
            #expect(user.email == "test@example.com")
        }
        
        @Test("User codable")
        func testUserCodable() async throws {
            let user = User(id: "user-456", email: "athlete@pulsar.app")
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(user)
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(User.self, from: data)
            
            #expect(decoded.id == user.id)
            #expect(decoded.email == user.email)
        }
    }
    
    // MARK: - Session Model Tests
    
    @Suite("Session Model")
    struct SessionModelTests {
        
        @Test("Session initialization")
        func testSessionInitialization() async throws {
            let session = Session(accessToken: "jwt-token-here", userId: "user-789")
            
            #expect(session.accessToken == "jwt-token-here")
            #expect(session.userId == "user-789")
        }
        
        @Test("Session codable")
        func testSessionCodable() async throws {
            let session = Session(accessToken: "eyJhbGc...", userId: "user-abc")
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(session)
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Session.self, from: data)
            
            #expect(decoded.accessToken == session.accessToken)
            #expect(decoded.userId == session.userId)
        }
    }
    
    // MARK: - Supabase Client Tests
    
    @Suite("Supabase Client")
    @MainActor
    struct SupabaseClientTests {
        
        @Test("Client singleton exists")
        func testClientSingleton() async throws {
            let client = SupabaseClient.shared
            #expect(client != nil)
        }
        
        @Test("Client is same instance")
        func testClientSameInstance() async throws {
            let client1 = SupabaseClient.shared
            let client2 = SupabaseClient.shared
            #expect(client1 === client2)
        }
    }
    
    // MARK: - User Profile Tests
    
    @Suite("User Profile")
    struct UserProfileTests {
        
        @Test("User profile initialization")
        func testUserProfileInitialization() async throws {
            let profile = UserProfile(
                userID: "user-1",
                username: "athlete",
                fullName: "John Doe",
                avatarURL: "https://example.com/avatar.jpg"
            )
            
            #expect(profile.userID == "user-1")
            #expect(profile.username == "athlete")
            #expect(profile.fullName == "John Doe")
            #expect(profile.avatarURL == "https://example.com/avatar.jpg")
        }
        
        @Test("User profile with nil values")
        func testUserProfileNilValues() async throws {
            let profile = UserProfile(
                userID: "user-2",
                username: "runner",
                fullName: nil,
                avatarURL: nil
            )
            
            #expect(profile.fullName == nil)
            #expect(profile.avatarURL == nil)
        }
        
        @Test("User profile codable")
        func testUserProfileCodable() async throws {
            let profile = UserProfile(
                userID: "user-3",
                username: "cyclist",
                fullName: "Jane Smith",
                avatarURL: nil
            )
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(UserProfile.self, from: data)
            
            #expect(decoded.userID == profile.userID)
            #expect(decoded.username == profile.username)
            #expect(decoded.fullName == profile.fullName)
        }
    }
}
