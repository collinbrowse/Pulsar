//
//  SupabaseClient.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import Foundation

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
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Log the error for debugging
            if let errorString = String(data: data, encoding: .utf8) {
                print("Supabase signup error (\(httpResponse.statusCode)): \(errorString)")
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Parse response - Supabase returns { "user": { "id": "...", "email": "..." }, ... }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let userDict = json?["user"] as? [String: Any],
              let userId = userDict["id"] as? String else {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Failed to parse user ID from response: \(jsonString)")
            }
            throw NetworkError.invalidData
        }
        
        return User(id: userId, email: email)
    }
    
    func signIn(email: String, password: String) async throws -> Session {
        let endpoint = baseURL.appendingPathComponent("/auth/v1/token")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "grant_type": "password"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Log the error for debugging
            if let errorString = String(data: data, encoding: .utf8) {
                print("Supabase signin error (\(httpResponse.statusCode)): \(errorString)")
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accessToken = json?["access_token"] as? String,
              let userDict = json?["user"] as? [String: Any],
              let userId = userDict["id"] as? String else {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Failed to parse session from response: \(jsonString)")
            }
            throw NetworkError.invalidData
        }
        
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
        
        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("app", forHTTPHeaderField: "Accept-Profile") // Use app schema
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("Supabase fetch error (\(httpResponse.statusCode)): \(errorString)")
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([T].self, from: data)
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
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("app", forHTTPHeaderField: "Content-Profile") // Use app schema for writes
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(data)
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: responseData, encoding: .utf8) {
                print("Supabase update error (\(httpResponse.statusCode)): \(errorString)")
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
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

