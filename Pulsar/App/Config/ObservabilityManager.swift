//
//  ObservabilityManager.swift
//  Pulsar
//
//  Created on 10/27/25.
//

import Foundation
import OSLog

/// Centralized manager for analytics, crash reporting, and logging
@MainActor
final class ObservabilityManager {
    static let shared = ObservabilityManager()
    
    private let logger = Logger(subsystem: "com.collinbrowse.Pulsar", category: "Observability")
    
    private init() {}
    
    // MARK: - Initialization
    
    func configure() {
        configureAnalytics()
        configureCrashlytics()
    }
    
    // MARK: - Analytics
    
    private func configureAnalytics() {
        guard FeatureFlags.shared.enableAnalytics else { return }
        
        guard let apiKey = AppEnvironment.shared.postHogAPIKey, !apiKey.isEmpty else {
            logger.warning("[Pulsar] PostHog API key not set")
            return
        }
        
        // Analytics SDK integration point.
        // PostHog.setup(withAPIKey: apiKey)
    }
    
    private func configureCrashlytics() {
        guard FeatureFlags.shared.enableCrashlytics else { return }
        
        // Crash reporting SDK integration point.
        // FirebaseCrashlytics.configure()
    }
    
    // MARK: - Event Tracking
    
    func track(event: String, properties: [String: String] = [:]) {
        guard FeatureFlags.shared.enableAnalytics else { return }
        
        logger.debug("Event: \(event) | Properties: \(String(describing: properties))")
        // When PostHog SDK is available, forward analytics events here:
        // PostHog.shared.capture(event, properties: properties)
    }
    
    // MARK: - Error Reporting
    
    func reportError(_ error: Error, context: [String: String] = [:]) {
        logger.error("Error: \(error.localizedDescription) | Context: \(String(describing: context))")
        
        guard FeatureFlags.shared.enableCrashlytics else { return }
        
        // When Crashlytics SDK is available, forward errors here:
        // Crashlytics.recordError(error, userInfo: context)
    }
    
    // MARK: - User Identity
    
    func identifyUser(_ userID: String, properties: [String: String] = [:]) {
        guard FeatureFlags.shared.enableAnalytics else { return }
        
        logger.info("User identified: \(userID)")
        // When PostHog SDK is available, forward identity updates here:
        // PostHog.shared.identify(userID, properties: properties)
    }
}
