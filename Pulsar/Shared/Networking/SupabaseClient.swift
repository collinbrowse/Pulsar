//
//  SupabaseClient.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import Foundation
import OSLog

// MARK: - Protocol

/// Abstraction for Supabase networking so that higher-level flows can be tested
/// against mock implementations without hitting the real network.
@MainActor
protocol SupabaseClientProtocol {
    func signUp(email: String, password: String, metadata: [String: String]) async throws -> User
    func signIn(email: String, password: String) async throws -> Session
    func refreshSession(refreshToken: String) async throws -> Session
    func fetch<T: Decodable>(
        from table: String,
        select: String,
        filter: [String: String],
        accessToken: String?,
        schema: String?
    ) async throws -> [T]
    func rpc<T: Decodable>(
        name: String,
        params: [String: Any],
        accessToken: String?,
        schema: String?
    ) async throws -> [T]
    func callFunction(
        name: String,
        body: Data?,
        accessToken: String?
    ) async throws -> Data
    
    func upsert<T: Encodable>(
        table: String,
        data: T,
        accessToken: String?,
        schema: String?
    ) async throws
}

/// Supabase API client for backend communication
@MainActor
final class SupabaseClient: SupabaseClientProtocol { // swiftlint:disable:this type_body_length
    static let shared = SupabaseClient()
    
    private static let networkLogger = Logger(subsystem: "com.collinbrowse.Pulsar", category: "Network")
    
    private let baseURL: URL
    private let anonKey: String
    
    private init() {
        let urlString = AppEnvironment.shared.supabaseURL
        guard let url = URL(string: urlString) else {
            fatalError("Invalid Supabase URL: \(urlString)")
        }
        self.baseURL = url
        self.anonKey = AppEnvironment.shared.supabaseAnonKey
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, metadata: [String: String] = [:]) async throws -> User {
        let endpoint = baseURL.appendingPathComponent("/auth/v1/signup")
        
        Self.networkLogger.info("📤 Signup Request: POST \(endpoint.absoluteString)")
        Self.networkLogger.debug("📤 Signup Body: email=\(email), metadata=\(metadata)")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": metadata
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        Self.logRequest(path: "/auth/v1/signup", method: "POST", bodySummary: "signUp email=\(email)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        Self.logResponse(path: "/auth/v1/signup", response: response, data: data)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            Self.networkLogger.error("❌ Signup: Invalid HTTP response")
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = Self.parseAuthErrorBody(data)
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, serverMessage: serverMessage)
        }
        
        // Parse response - Supabase returns user object directly at top level
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let userId = json?["id"] as? String else {
            if let jsonString = String(data: data, encoding: .utf8) {
                Self.networkLogger.error("❌ Failed to parse user ID from response: \(jsonString)")
                print("Failed to parse user ID from response: \(jsonString)")
            }
            throw NetworkError.invalidData
        }
        
        Self.networkLogger.info("✅ Signup Success: userId=\(userId)")
        return User(id: userId, email: email)
    }
    
    func signIn(email: String, password: String) async throws -> Session {
        // GoTrue requires grant_type as a query parameter; body is JSON with email/password only.
        guard var components = URLComponents(url: baseURL.appendingPathComponent("/auth/v1/token"), resolvingAgainstBaseURL: true) else {
            throw NetworkError.invalidResponse
        }
        components.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        guard let endpoint = components.url else {
            throw NetworkError.invalidResponse
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        Self.logRequest(path: "/auth/v1/token", method: "POST", bodySummary: "signIn email=\(email)")
        
        let (data, response) = try await URLSession.shared.data(for: request)

        Self.logResponse(path: "/auth/v1/token", response: response, data: data)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = Self.parseAuthErrorBody(data)
                ?? Self.signInFriendlyMessage(statusCode: httpResponse.statusCode)
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, serverMessage: serverMessage)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accessToken = json?["access_token"] as? String,
              let refreshToken = json?["refresh_token"] as? String,
              let userDict = json?["user"] as? [String: Any],
              let userId = userDict["id"] as? String else {
            if let jsonString = String(data: data, encoding: .utf8) {
                Self.networkLogger.error("❌ Failed to parse session from response: \(jsonString)")
                print("Failed to parse session from response: \(jsonString)")
            }
            throw NetworkError.invalidData
        }
        let expiresIn = json?["expires_in"] as? Int

        return Session(
            accessToken: accessToken,
            userId: userId,
            refreshToken: refreshToken,
            expiresInSeconds: expiresIn
        )
    }

    /// Restore session using a saved refresh token (e.g. on app launch).
    func refreshSession(refreshToken: String) async throws -> Session {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("/auth/v1/token"), resolvingAgainstBaseURL: true) else {
            throw NetworkError.invalidResponse
        }
        components.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]
        guard let endpoint = components.url else {
            throw NetworkError.invalidResponse
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let body: [String: Any] = ["refresh_token": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        Self.logRequest(path: "/auth/v1/token", method: "POST", bodySummary: "refresh_token")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        Self.logResponse(path: "/auth/v1/token", response: response, data: data)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = Self.parseAuthErrorBody(data)
                ?? Self.signInFriendlyMessage(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
            throw NetworkError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, serverMessage: serverMessage)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accessToken = json?["access_token"] as? String,
              let userId = (json?["user"] as? [String: Any])?["id"] as? String else {
            throw NetworkError.invalidData
        }
        let newRefreshToken = json?["refresh_token"] as? String ?? refreshToken
        let expiresIn = json?["expires_in"] as? Int

        return Session(
            accessToken: accessToken,
            userId: userId,
            refreshToken: newRefreshToken,
            expiresInSeconds: expiresIn
        )
    }
    
    // MARK: - REST API
    
    func fetch<T: Decodable>(
        from table: String,
        select: String = "*",
        filter: [String: String] = [:],
        accessToken: String? = nil,
        schema: String? = nil
    ) async throws -> [T] {
        guard let baseComponents = URLComponents(
            url: baseURL.appendingPathComponent("/rest/v1/\(table)"),
            resolvingAgainstBaseURL: true
        ) else {
            throw NetworkError.invalidResponse
        }

        var components = baseComponents
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "select", value: select)
        ]
        
        for (key, value) in filter {
            queryItems.append(URLQueryItem(name: key, value: "eq.\(value)"))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw NetworkError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }
        if let schema = schema {
            request.setValue(schema, forHTTPHeaderField: "Accept-Profile")
        }
        
        Self.logRequest(path: "/rest/v1/\(table)", method: "GET", bodySummary: "select=\(select)")
        
        let (data, response) = try await URLSession.shared.data(for: request)

        Self.logResponse(path: "/rest/v1/\(table)", response: response, data: data)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, serverMessage: nil)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([T].self, from: data)
    }

    /// Calls a Supabase PostgREST RPC (e.g. app.get_user_feed). Returns decoded rows.
    func rpc<T: Decodable>(
        name: String,
        params: [String: Any] = [:],
        accessToken: String? = nil,
        schema: String? = nil
    ) async throws -> [T] {
        let endpoint = baseURL.appendingPathComponent("/rest/v1/rpc/\(name)")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let schema = schema {
            request.setValue(schema, forHTTPHeaderField: "Accept-Profile")
            request.setValue(schema, forHTTPHeaderField: "Content-Profile")
        }

        if !params.isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: params)
        }

        Self.logRequest(path: "/rest/v1/rpc/\(name)", method: "POST", bodySummary: "\(params.count) params")

        let (data, response) = try await URLSession.shared.data(for: request)

        Self.logResponse(path: "/rest/v1/rpc/\(name)", response: response, data: data)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, serverMessage: nil)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([T].self, from: data)
    }
    
    // MARK: - Edge Functions
    
    /// Calls a Supabase Edge Function. Pass pre-encoded JSON as `body` (e.g. `try JSONEncoder().encode(myPayload)`) for Swift 6 Sendable safety.
    func callFunction(
        name: String,
        body: Data? = nil,
        accessToken: String? = nil
    ) async throws -> Data {
        let endpoint = baseURL.appendingPathComponent("/functions/v1/\(name)")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        Self.logRequest(path: "/functions/v1/\(name)", method: "POST", bodySummary: body.map { "\($0.count) bytes" } ?? "none")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        Self.logResponse(path: "/functions/v1/\(name)", response: response, data: data)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, serverMessage: nil)
        }
        
        return data
    }
    
    /// PostgREST upsert (insert or update on conflict). Uses `app` or `public` schema via Content-Profile.
    func upsert<T: Encodable>(
        table: String,
        data: T,
        accessToken: String?,
        schema: String?
    ) async throws {
        let endpoint = baseURL.appendingPathComponent("/rest/v1/\(table)")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("return=minimal,resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let schema {
            request.setValue(schema, forHTTPHeaderField: "Accept-Profile")
            request.setValue(schema, forHTTPHeaderField: "Content-Profile")
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(data)
        
        Self.logRequest(path: "/rest/v1/\(table)", method: "POST", bodySummary: "upsert")
        
        let (bodyData, response) = try await URLSession.shared.data(for: request)
        
        Self.logResponse(path: "/rest/v1/\(table)", response: response, data: bodyData)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let msg = Self.parseAuthErrorBody(bodyData)
            throw NetworkError.httpError(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                serverMessage: msg
            )
        }
    }

    // MARK: - Network logging
    
    private static func logRequest(path: String, method: String, bodySummary: String) {
        networkLogger.debug("[Request] \(method) \(path) body=\(bodySummary)")
    }
    
    private static func logResponse(path: String, response: URLResponse?, data: Data) {
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        if (200...299).contains(status) {
            networkLogger.debug("[Response] \(path) status=\(status)")
        } else {
            let bodyPreview = String(data: data, encoding: .utf8)
                .map { $0.prefix(500) } ?? "\(data.count) bytes (non-UTF8)"
            networkLogger.warning("[Response] \(path) status=\(status) body=\(bodyPreview)")
        }
    }
    
    // MARK: - Auth error parsing
    
    /// Parses Supabase Auth error response body for a user-facing message.
    /// Prefers `msg`, then `error_description`, then a message derived from `error`/`code`.
    private static func parseAuthErrorBody(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let msg = json["msg"] as? String, !msg.isEmpty { return msg }
        if let desc = json["error_description"] as? String, !desc.isEmpty { return desc }
        if let code = json["error"] as? String, !code.isEmpty {
            return friendlyMessage(forAuthCode: code)
        }
        if let code = json["code"] as? String, !code.isEmpty {
            return friendlyMessage(forAuthCode: code)
        }
        return nil
    }
    
    private static func friendlyMessage(forAuthCode code: String) -> String {
        switch code {
        case "email_exists", "user_already_exists":
            return "This email is already registered. Try signing in or use a different email."
        case "email_address_invalid":
            return "Please use a valid email address. Example and test domains are not supported."
        case "email_address_not_authorized":
            return "This email cannot be used with sign up right now. Contact support if this persists."
        case "weak_password":
            return "Password doesn’t meet requirements. Use at least 8 characters and a mix of letters and numbers."
        case "validation_failed":
            return "Invalid email or password. Check the format and try again."
        case "signup_disabled", "email_provider_disabled":
            return "Sign up is currently unavailable. Please try again later."
        case "invalid_credentials":
            return "Invalid email or password. Please try again."
        case "email_not_confirmed":
            return "Please confirm your email address before signing in. Check your inbox for the verification link."
        case "unsupported_grant_type":
            return "Sign-in request was invalid. Please try again."
        default:
            return code.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    /// Fallback message when sign-in fails and the response body can't be parsed.
    private static func signInFriendlyMessage(statusCode: Int) -> String {
        switch statusCode {
        case 401:
            return "Invalid email or password. Please try again."
        case 422:
            return "We couldn’t sign you in. Check your email and password and try again."
        default:
            return "Sign-in failed. Please try again."
        }
    }
}

// MARK: - Errors

enum NetworkError: Error, LocalizedError, Sendable {
    case invalidResponse
    case invalidData
    case httpError(statusCode: Int, serverMessage: String?)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .invalidData:
            return "Invalid data received"
        case .httpError(let code, let serverMessage):
            if let msg = serverMessage, !msg.isEmpty {
                return msg
            }
            return "HTTP error: \(code)"
        case .unauthorized:
            return "Authentication required"
        }
    }
}
