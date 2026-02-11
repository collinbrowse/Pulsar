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
        // When Crashlytics SDK is available, forward errors here:
        // Crashlytics.recordError(error, userInfo: context)
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
        logger.error("""
        Error Reported:
          Type: \(errorType)
          User Message: \(userMessage)
          Technical: \(technicalDetails)
          Context: \(context)
          Severity: \(severity.rawValue)
          Recoverable: \(recoverable)
        """)

        if FeatureFlags.shared.enableCrashlytics {
            let _: [String: Any] = [
                "error_type": errorType,
                "user_message": userMessage,
                "technical_details": technicalDetails,
                "context": context,
                "severity": severity.rawValue,
                "recoverable": recoverable
            ]
            // TODO: Crashlytics.recordError(error, userInfo: crashContext)
        }

        if FeatureFlags.shared.enableAnalytics {
            let properties: [String: String] = [
                "error_type": errorType,
                "user_message": userMessage,
                "technical_details": technicalDetails,
                "context": context.isEmpty ? "none" : context,
                "severity": severity.rawValue,
                "recoverable": String(recoverable),
                "platform": "iOS",
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            ]
            track(event: "error_detailed", properties: properties)
        }
    }
    
    // MARK: - User Identity

    func identifyUser(_ userID: String, properties: [String: String] = [:]) {
        guard FeatureFlags.shared.enableAnalytics else { return }

        logger.info("User identified: \(userID)")
        // When PostHog SDK is available, forward identity updates here:
        // PostHog.shared.identify(userID, properties: properties)
    }
}

/// Error severity levels for product analytics
enum ErrorSeverity: String {
    case low           // Cosmetic, doesn't block user
    case medium        // Impacts UX but has workaround
    case high          // Blocks key functionality
    case critical      // App-breaking, requires immediate fix
}
