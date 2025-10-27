//
//  AuthenticationServiceTests.swift
//  PulsarTests
//
//  Created on 10/27/25.
//

import Testing
import Foundation
@testable import Pulsar

@Suite("Authentication Service Tests")
@MainActor
struct AuthenticationServiceTests {
    
    @Test("Authentication service should be singleton")
    func testSingleton() {
        let service1 = AuthenticationService.shared
        let service2 = AuthenticationService.shared
        
        #expect(service1 === service2)
    }
    
    @Test("Initially user should not be authenticated")
    func testInitialState() {
        let service = AuthenticationService.shared
        
        #expect(service.isAuthenticated == false)
        #expect(service.currentUserID == nil)
        #expect(service.accessToken == nil)
    }
    
    @Test("Email validation should reject invalid emails")
    func testEmailValidation() async throws {
        let service = AuthenticationService.shared
        
        // Test invalid emails - should throw
        do {
            _ = try await service.signUp(
                email: "invalid-email",
                password: "password123",
                username: "testuser",
                fullName: nil
            )
            Issue.record("Should have thrown invalidEmail error")
        } catch let error as AuthError {
            #expect(error == .invalidEmail)
        }
        
        do {
            _ = try await service.signUp(
                email: "test@",
                password: "password123",
                username: "testuser",
                fullName: nil
            )
            Issue.record("Should have thrown invalidEmail error")
        } catch let error as AuthError {
            #expect(error == .invalidEmail)
        }
    }
    
    @Test("Password validation should require minimum length")
    func testPasswordValidation() async throws {
        let service = AuthenticationService.shared
        
        // Test short password - should throw
        do {
            _ = try await service.signUp(
                email: "test@example.com",
                password: "short",
                username: "testuser",
                fullName: nil
            )
            Issue.record("Should have thrown passwordTooShort error")
        } catch let error as AuthError {
            #expect(error == .passwordTooShort)
        }
    }
    
    @Test("Username validation should enforce length limits")
    func testUsernameValidation() async throws {
        let service = AuthenticationService.shared
        
        // Test too short username
        do {
            _ = try await service.signUp(
                email: "test@example.com",
                password: "password123",
                username: "ab",
                fullName: nil
            )
            Issue.record("Should have thrown usernameTooShort error")
        } catch let error as AuthError {
            #expect(error == .usernameTooShort)
        }
        
        // Test too long username
        do {
            _ = try await service.signUp(
                email: "test@example.com",
                password: "password123",
                username: "a".padding(toLength: 31, withPad: "a", startingAt: 0),
                fullName: nil
            )
            Issue.record("Should have thrown usernameTooLong error")
        } catch let error as AuthError {
            #expect(error == .usernameTooLong)
        }
    }
    
    @Test("Username validation should only allow alphanumeric and special chars")
    func testUsernameFormat() async throws {
        let service = AuthenticationService.shared
        
        // Test invalid characters
        do {
            _ = try await service.signUp(
                email: "test@example.com",
                password: "password123",
                username: "user@name",
                fullName: nil
            )
            Issue.record("Should have thrown invalidUsername error")
        } catch let error as AuthError {
            #expect(error == .invalidUsername)
        }
    }
    
    @Test("Sign out should clear session")
    func testSignOut() {
        let service = AuthenticationService.shared
        
        service.signOut()
        
        #expect(service.isAuthenticated == false)
        #expect(service.currentUserID == nil)
    }
    
    @Test("Auth error should have descriptive messages")
    func testAuthErrorDescriptions() {
        #expect(AuthError.notAuthenticated.localizedDescription == "You must be signed in to perform this action")
        #expect(AuthError.invalidEmail.localizedDescription == "Please enter a valid email address")
        #expect(AuthError.passwordTooShort.localizedDescription == "Password must be at least 8 characters")
        #expect(AuthError.usernameTooShort.localizedDescription == "Username must be at least 3 characters")
        #expect(AuthError.usernameTooLong.localizedDescription == "Username must be no more than 30 characters")
        #expect(AuthError.invalidUsername.localizedDescription == "Username can only contain letters, numbers, hyphens, and underscores")
    }
}

