//
//  SupabaseClient.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.collinbrowse.Pulsar", category: "SupabaseClient")

/// Supabase API client for backend communication
@MainActor
final class SupabaseClient: Sendable {
    static let shared = SupabaseClient()
    
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
    
    func signUp(email: String, password: String, metadata: [String: Any] = [:]) async throws -> User {
        let endpoint = baseURL.appendingPathComponent("/auth/v1/signup")
        
        logger.info("📤 Signup Request: POST \(endpoint.absoluteString)")
        logger.debug("📤 Signup Body: email=\(email), metadata=\(metadata)")
        
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("❌ Signup: Invalid HTTP response")
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Log the error for debugging
            if let errorString = String(data: data, encoding: .utf8) {
                logger.error("❌ Signup Error (\(httpResponse.statusCode)): \(errorString)")
                print("Supabase signup error (\(httpResponse.statusCode)): \(errorString)")
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Parse response - Supabase returns user object directly at top level
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let userId = json?["id"] as? String else {
            if let jsonString = String(data: data, encoding: .utf8) {
                logger.error("❌ Failed to parse user ID from response: \(jsonString)")
                print("Failed to parse user ID from response: \(jsonString)")
            }
            throw NetworkError.invalidData
        }
        
        logger.info("✅ Signup Success: userID=\(userId)")
        return User(id: userId, email: email)
    }
    
    func signIn(email: String, password: String) async throws -> Session {
        // Build URL with grant_type as query parameter
        var components = URLComponents(url: baseURL.appendingPathComponent("/auth/v1/token"), resolvingAgainstBaseURL: true)!
        components.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        
        guard let endpoint = components.url else {
            logger.error("❌ SignIn: Failed to build URL")
            throw NetworkError.invalidResponse
        }
        
        logger.info("📤 SignIn Request: POST \(endpoint.absoluteString)")
        logger.debug("📤 SignIn Body: email=\(email)")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("❌ SignIn: Invalid HTTP response")
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Log the error for debugging
            if let errorString = String(data: data, encoding: .utf8) {
                logger.error("❌ SignIn Error (\(httpResponse.statusCode)): \(errorString)")
                print("Supabase signin error (\(httpResponse.statusCode)): \(errorString)")
                
                // Parse error details if available
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let errorCode = errorJson["error_code"] as? String {
                        logger.error("   Error Code: \(errorCode)")
                    }
                    if let msg = errorJson["msg"] as? String {
                        logger.error("   Message: \(msg)")
                    }
                }
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accessToken = json?["access_token"] as? String,
              let userDict = json?["user"] as? [String: Any],
              let userId = userDict["id"] as? String else {
            if let jsonString = String(data: data, encoding: .utf8) {
                logger.error("❌ Failed to parse session from response: \(jsonString)")
                print("Failed to parse session from response: \(jsonString)")
            }
            throw NetworkError.invalidData
        }
        
        logger.info("✅ SignIn Success: userID=\(userId)")
        return Session(accessToken: accessToken, userId: userId)
    }
    
    // MARK: - REST API
    
    func fetch<T: Decodable>(
        from table: String,
        select: String = "*",
        filter: [String: Any] = [:],
        accessToken: String? = nil
    ) async throws -> [T] {
        var components = URLComponents(url: baseURL.appendingPathComponent("/rest/v1/\(table)"), resolvingAgainstBaseURL: true)!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "select", value: select)
        ]
        
        for (key, value) in filter {
            queryItems.append(URLQueryItem(name: key, value: "eq.\(value)"))
        }
        
        components.queryItems = queryItems
        
        logger.info("📤 Fetch Request: GET \(components.url!.absoluteString)")
        logger.debug("   Table: \(table), Filters: \(filter)")
        
        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("public", forHTTPHeaderField: "Accept-Profile") // Use public schema
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            logger.debug("   Using access token: \(token.prefix(20))...")
        } else {
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
            logger.debug("   Using anon key")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("❌ Fetch: Invalid HTTP response")
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                logger.error("❌ Fetch Error (\(httpResponse.statusCode)): \(errorString)")
                print("Supabase fetch error (\(httpResponse.statusCode)): \(errorString)")
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        logger.info("✅ Fetch Success: \(data.count) bytes received")
        
        // Log the actual response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            logger.debug("   Response: \(responseString)")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode([T].self, from: data)
        logger.debug("   Decoded \(result.count) items")
        return result
    }
    
    func upsert<T: Encodable>(
        table: String,
        data: T,
        accessToken: String
    ) async throws {
        let endpoint = baseURL.appendingPathComponent("/rest/v1/\(table)")
        
        logger.info("📤 Upsert Request: POST \(endpoint.absoluteString)")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("public", forHTTPHeaderField: "Content-Profile") // Use public schema for writes
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer") // Upsert on conflict
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(data)
        
        if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
            logger.debug("   Body: \(bodyString)")
        }
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("❌ Upsert: Invalid HTTP response")
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: responseData, encoding: .utf8) {
                logger.error("❌ Upsert Error (\(httpResponse.statusCode)): \(errorString)")
                print("Supabase upsert error (\(httpResponse.statusCode)): \(errorString)")
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        if let responseString = String(data: responseData, encoding: .utf8) {
            logger.info("✅ Upsert Success - Response: \(responseString)")
        } else {
            logger.info("✅ Upsert Success")
        }
    }
    
    func update<T: Encodable>(
        table: String,
        data: T,
        filter: [String: Any],
        accessToken: String
    ) async throws {
        var components = URLComponents(url: baseURL.appendingPathComponent("/rest/v1/\(table)"), resolvingAgainstBaseURL: true)!
        
        var queryItems: [URLQueryItem] = []
        for (key, value) in filter {
            queryItems.append(URLQueryItem(name: key, value: "eq.\(value)"))
        }
        components.queryItems = queryItems
        
        logger.info("📤 Update Request: PATCH \(components.url!.absoluteString)")
        logger.debug("   Table: \(table), Filters: \(filter)")
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("public", forHTTPHeaderField: "Content-Profile") // Use public schema for writes
        request.setValue("return=representation", forHTTPHeaderField: "Prefer") // Return updated rows
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(data)
        
        if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
            logger.debug("   Body: \(bodyString)")
        }
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("❌ Update: Invalid HTTP response")
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: responseData, encoding: .utf8) {
                logger.error("❌ Update Error (\(httpResponse.statusCode)): \(errorString)")
                print("Supabase update error (\(httpResponse.statusCode)): \(errorString)")
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Log the response to verify rows were updated
        if let responseString = String(data: responseData, encoding: .utf8) {
            logger.info("✅ Update Success - Response: \(responseString)")
            if responseString == "[]" || responseString.isEmpty {
                logger.warning("⚠️ Update returned empty response - no rows were updated!")
            }
        } else {
            logger.info("✅ Update Success")
        }
    }
    
    // MARK: - Edge Functions
    
    func callFunction(
        name: String,
        body: [String: Any]? = nil,
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
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        return data
    }
}

// MARK: - Models

struct User: Codable, Sendable {
    let id: String
    let email: String
}

struct Session: Codable, Sendable {
    let accessToken: String
    let userId: String
}

// MARK: - Errors

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case invalidData
    case httpError(statusCode: Int)
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .invalidData:
            return "Invalid data received"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .unauthorized:
            return "Authentication required"
        }
    }
}

