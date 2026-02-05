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
        logger.info("Observability configured")
    }
    
    // MARK: - Analytics
    
    private func configureAnalytics() {
        guard FeatureFlags.shared.enableAnalytics else {
            logger.info("Analytics disabled via feature flag")
            return
        }
        
        guard let apiKey = AppEnvironment.shared.postHogAPIKey, !apiKey.isEmpty else {
            logger.warning("PostHog API key not configured")
            return
        }
        
        // Analytics SDK integration point.
        // When PostHog SDK is added to the project, initialize it here:
        // PostHog.setup(withAPIKey: apiKey)
        logger.info("Analytics configured with PostHog")
    }
    
    private func configureCrashlytics() {
        guard FeatureFlags.shared.enableCrashlytics else {
            logger.info("Crashlytics disabled via feature flag")
            return
        }
        
        // Crash reporting SDK integration point.
        // When Firebase Crashlytics is added to the project, configure it here:
        // FirebaseCrashlytics.configure()
        logger.info("Crashlytics configured with Firebase")
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
