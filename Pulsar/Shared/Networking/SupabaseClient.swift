//
//  SupabaseClient.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import Foundation

/// Supabase API client for backend communication
@MainActor
final class SupabaseClient {
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
    
    func signUp(email: String, password: String, metadata: [String: String] = [:]) async throws -> User {
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
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let userId = json?["id"] as? String else {
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
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.unauthorized
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accessToken = json?["access_token"] as? String,
              let userId = (json?["user"] as? [String: Any])?["id"] as? String else {
            throw NetworkError.invalidData
        }
        
        return Session(accessToken: accessToken, userId: userId)
    }
    
    // MARK: - REST API
    
    func fetch<T: Decodable>(
        from table: String,
        select: String = "*",
        filter: [String: String] = [:],
        accessToken: String? = nil
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
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        return data
    }
}

// MARK: - Errors

enum NetworkError: Error, LocalizedError, Sendable {
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
