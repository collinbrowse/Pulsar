//
//  AuthFlow.swift
//  Pulsar
//
//  Testable authentication flow that wires SupabaseClient to AppState.
//

import Foundation

@MainActor
enum AuthMode {
    case signUp
    case signIn
}

struct AuthRequest {
    let mode: AuthMode
    let email: String
    let password: String
    let fullName: String?
}

/// Encapsulates the core authentication behavior so it can be tested in
/// isolation from SwiftUI views. This connects a `SupabaseClientProtocol`
/// implementation to `AppState` and defines the contract we rely on in the UI.
@MainActor
enum AuthFlow {
    static func authenticate(
        request: AuthRequest,
        client: SupabaseClientProtocol,
        appState: AppState
    ) async throws {
        switch request.mode {
        case .signUp:
            let user = try await client.signUp(
                email: request.email,
                password: request.password,
                metadata: ["full_name": request.fullName ?? ""]
            )
            appState.currentUserID = user.id
            appState.isAuthenticated = true
            
        case .signIn:
            let session = try await client.signIn(
                email: request.email,
                password: request.password
            )
            appState.setAuthenticated(
                userId: session.userId,
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                profile: nil
            )
        }
    }
}
