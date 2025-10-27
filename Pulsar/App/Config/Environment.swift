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
        self.supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] 
            ?? "https://jlyamkhkgjkktiypywkk.supabase.co"
        self.supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] 
            ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpseWFta2hrZ2pra3RpeXB5d2trIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1ODQ4OTMsImV4cCI6MjA3NzE2MDg5M30.-KuWVRKDxZo9m6iRgidFs5N7cHeLAp9OfzAUYtUCC2I"
        self.postHogAPIKey = ProcessInfo.processInfo.environment["POSTHOG_API_KEY"]
            ?? "phc_IpkCg9gHDdE2leENq0RIlHfCJFY2OSdMHHiDibeNriF"
        self.mapboxToken = ProcessInfo.processInfo.environment["MAPBOX_TOKEN"]
    }
    
    var isConfigured: Bool {
        !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty
    }
}

