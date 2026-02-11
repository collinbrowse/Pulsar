//
//  AuthFlowTests.swift
//  PulsarTests
//
//  Tests for authentication flow wiring SupabaseClient to AppState.
//

import Foundation
@testable import Pulsar
import Testing

@Suite("Auth Flow Tests")
@MainActor
struct AuthFlowTests {
    // MARK: - Mocks
    
    final class MockSupabaseClient: SupabaseClientProtocol {
        var signUpEmail: String?
        var signUpPassword: String?
        var signUpMetadata: [String: String]?
        var signUpResult: User?
        var signUpError: Error?
        
        var signInEmail: String?
        var signInPassword: String?
        var signInResult: Session?
        var signInError: Error?
        
        func signUp(email: String, password: String, metadata: [String: String]) async throws -> User {
            signUpEmail = email
            signUpPassword = password
            signUpMetadata = metadata
            
            if let error = signUpError {
                throw error
            }
            if let user = signUpResult {
                return user
            }
            return User(id: "mock-user-id", email: email)
        }
        
        func signIn(email: String, password: String) async throws -> Session {
            signInEmail = email
            signInPassword = password
            
            if let error = signInError {
                throw error
            }
            if let session = signInResult {
                return session
            }
            return Session(accessToken: "mock-token", userId: "mock-user-id")
        }
        
        func fetch<T>(
            from table: String,
            select: String,
            filter: [String: String],
            accessToken: String?,
            schema: String?
        ) async throws -> [T] where T: Decodable {
            []
        }
        
        func rpc<T: Decodable>(
            name: String,
            params: [String: Any],
            accessToken: String?,
            schema: String?
        ) async throws -> [T] {
            []
        }
        
        func callFunction(
            name: String,
            body: Data?,
            accessToken: String?
        ) async throws -> Data {
            Data()
        }
    }
    
    // MARK: - Sign Up
    
    @Test("Successful sign up updates AppState")
    func testSignUpSuccess() async throws {
        let appState = AppState()
        let mockClient = MockSupabaseClient()
        mockClient.signUpResult = User(id: "user-123", email: "test@example.com")
        
        #expect(appState.isAuthenticated == false)
        #expect(appState.currentUserID == nil)
        
        let request = AuthRequest(
            mode: .signUp,
            email: "test@example.com",
            password: "password123",
            fullName: "Test User"
        )
        
        try await AuthFlow.authenticate(
            request: request,
            client: mockClient,
            appState: appState
        )
        
        #expect(appState.isAuthenticated == true)
        #expect(appState.currentUserID == "user-123")
        #expect(mockClient.signUpEmail == "test@example.com")
        #expect(mockClient.signUpMetadata?["full_name"] == "Test User")
    }
    
    @Test("Sign up failure does not authenticate user")
    func testSignUpFailure() async throws {
        let appState = AppState()
        let mockClient = MockSupabaseClient()
        mockClient.signUpError = NetworkError.httpError(statusCode: 400, serverMessage: nil)
        
        try await #expect(throws: Error.self) {
            let request = AuthRequest(
                mode: .signUp,
                email: "test@example.com",
                password: "password123",
                fullName: "Test User"
            )
            
            try await AuthFlow.authenticate(
                request: request,
                client: mockClient,
                appState: appState
            )
        }
        
        #expect(appState.isAuthenticated == false)
        #expect(appState.currentUserID == nil)
    }
    
    // MARK: - Sign In
    
    @Test("Successful sign in updates AppState")
    func testSignInSuccess() async throws {
        let appState = AppState()
        let mockClient = MockSupabaseClient()
        mockClient.signInResult = Session(accessToken: "token-123", userId: "user-456")
        
        let request = AuthRequest(
            mode: .signIn,
            email: "login@example.com",
            password: "password123",
            fullName: nil
        )
        
        try await AuthFlow.authenticate(
            request: request,
            client: mockClient,
            appState: appState
        )
        
        #expect(appState.isAuthenticated == true)
        #expect(appState.currentUserID == "user-456")
        #expect(mockClient.signInEmail == "login@example.com")
    }
    
    @Test("Sign in failure does not authenticate user")
    func testSignInFailure() async throws {
        let appState = AppState()
        let mockClient = MockSupabaseClient()
        mockClient.signInError = NetworkError.unauthorized
        
        try await #expect(throws: Error.self) {
            let request = AuthRequest(
                mode: .signIn,
                email: "login@example.com",
                password: "wrong-password",
                fullName: nil
            )
            
            try await AuthFlow.authenticate(
                request: request,
                client: mockClient,
                appState: appState
            )
        }
        
        #expect(appState.isAuthenticated == false)
        #expect(appState.currentUserID == nil)
    }
}
