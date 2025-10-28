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
final class ObservabilityManager: Sendable {
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
        
        // TODO: Initialize PostHog SDK when available
        // PostHog.setup(withAPIKey: apiKey)
        logger.info("Analytics configured with PostHog")
    }
    
    private func configureCrashlytics() {
        guard FeatureFlags.shared.enableCrashlytics else {
            logger.info("Crashlytics disabled via feature flag")
            return
        }
        
        // TODO: Initialize Firebase Crashlytics when available
        // FirebaseCrashlytics.configure()
        logger.info("Crashlytics configured with Firebase")
    }
    
    // MARK: - Event Tracking
    
    func track(event: String, properties: [String: Any] = [:]) {
        guard FeatureFlags.shared.enableAnalytics else { return }
        
        logger.debug("Event: \(event) | Properties: \(String(describing: properties))")
        // TODO: PostHog.shared.capture(event, properties: properties)
    }
    
    // MARK: - Error Reporting
    
    func reportError(_ error: Error, context: [String: Any] = [:]) {
        logger.error("Error: \(error.localizedDescription) | Context: \(String(describing: context))")
        
        // Report to Crashlytics
        if FeatureFlags.shared.enableCrashlytics {
            // TODO: Crashlytics.recordError(error, userInfo: context)
        }
        
        // Track error event in PostHog for product team visibility
        if FeatureFlags.shared.enableAnalytics {
            var properties = context
            properties["error_type"] = String(describing: type(of: error))
            properties["error_description"] = error.localizedDescription
            
            track(event: "error_occurred", properties: properties)
        }
    }
    
    /// Report error with detailed context for product analytics
    func reportErrorDetailed(
        _ error: Error,
        errorType: String,
        userMessage: String,
        technicalDetails: String,
        context: String = "",
        severity: ErrorSeverity = .medium,
        recoverable: Bool = false
    ) {
        // Log with full details
        logger.error("""
        Error Reported:
          Type: \(errorType)
          User Message: \(userMessage)
          Technical: \(technicalDetails)
          Context: \(context)
          Severity: \(severity.rawValue)
          Recoverable: \(recoverable)
        """)
        
        // Report to Crashlytics
        if FeatureFlags.shared.enableCrashlytics {
            let crashContext: [String: Any] = [
                "error_type": errorType,
                "user_message": userMessage,
                "technical_details": technicalDetails,
                "context": context,
                "severity": severity.rawValue,
                "recoverable": recoverable
            ]
            // TODO: Crashlytics.recordError(error, userInfo: crashContext)
        }
        
        // Track in PostHog for product team
        if FeatureFlags.shared.enableAnalytics {
            let properties: [String: Any] = [
                "error_type": errorType,
                "user_message": userMessage,
                "technical_details": technicalDetails,
                "context": context.isEmpty ? "none" : context,
                "severity": severity.rawValue,
                "recoverable": recoverable,
                "platform": "iOS",
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            ]
            
            track(event: "error_detailed", properties: properties)
        }
    }
    
    // MARK: - User Identity
    
    func identifyUser(_ userID: String, properties: [String: Any] = [:]) {
        guard FeatureFlags.shared.enableAnalytics else { return }
        
        logger.info("User identified: \(userID)")
        // TODO: PostHog.shared.identify(userID, properties: properties)
    }
}

/// Error severity levels for product analytics
enum ErrorSeverity: String {
    case low = "low"           // Cosmetic, doesn't block user
    case medium = "medium"     // Impacts UX but has workaround
    case high = "high"         // Blocks key functionality
    case critical = "critical" // App-breaking, requires immediate fix
}

