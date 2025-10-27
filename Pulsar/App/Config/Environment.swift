//
//  Environment.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import Foundation

/// Environment configuration for backend services and API keys
struct AppEnvironment: Sendable {
    static let shared = AppEnvironment()
    
    // MARK: - Supabase
    
    let supabaseURL: String
    let supabaseAnonKey: String
    
    // MARK: - Analytics
    
    let postHogAPIKey: String?
    
    // MARK: - Maps
    
    let mapboxToken: String?
    
    // MARK: - Initialization
    
    private init() {
        // Load from environment variables or plist
        // In production, these would be loaded from a secure configuration
        self.supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        self.supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
        self.postHogAPIKey = ProcessInfo.processInfo.environment["POSTHOG_API_KEY"]
        self.mapboxToken = ProcessInfo.processInfo.environment["MAPBOX_TOKEN"]
    }
    
    var isConfigured: Bool {
        !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty
    }
}

