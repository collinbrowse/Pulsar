//
//  ErrorManager.swift
//  Pulsar
//
//  Created on 10/28/25.
//

import Foundation

/// Centralized error management system for user-friendly error messages
enum AppError: Error {
    // Authentication Errors
    case userAlreadyExists
    case emailNotConfirmed
    case invalidCredentials
    case weakPassword
    case invalidEmail
    case invalidUsername
    case authenticationRequired
    
    // Network Errors
    case networkError
    case serverError
    case timeout
    
    // Validation Errors
    case validationError(String)
    
    // Generic
    case unknown(String)
    
    /// User-friendly error message
    var userMessage: String {
        switch self {
        // Authentication
        case .userAlreadyExists:
            return "An account with this email already exists. Signing you in..."
        case .emailNotConfirmed:
            return "Please confirm your email address before signing in."
        case .invalidCredentials:
            return "Incorrect email or password. Please try again."
        case .weakPassword:
            return "Password must be at least 8 characters long."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidUsername:
            return "Username must be 3-30 characters and contain only letters, numbers, hyphens, and underscores."
        case .authenticationRequired:
            return "Please sign in to continue."
            
        // Network
        case .networkError:
            return "Unable to connect. Please check your internet connection."
        case .serverError:
            return "Our servers are experiencing issues. Please try again later."
        case .timeout:
            return "Request timed out. Please try again."
            
        // Validation
        case .validationError(let message):
            return message
            
        // Generic
        case .unknown(_):
            return "Something went wrong. Please try again."
        }
    }
    
    /// Technical error description (for logging)
    var technicalDescription: String {
        switch self {
        case .userAlreadyExists:
            return "User already exists (422: user_already_exists)"
        case .emailNotConfirmed:
            return "Email not confirmed (400: email_not_confirmed)"
        case .invalidCredentials:
            return "Invalid credentials (400/401)"
        case .weakPassword:
            return "Password too weak"
        case .invalidEmail:
            return "Invalid email format"
        case .invalidUsername:
            return "Invalid username format"
        case .authenticationRequired:
            return "Authentication required (401: unauthorized)"
        case .networkError:
            return "Network connection error"
        case .serverError:
            return "Server error (5xx)"
        case .timeout:
            return "Request timeout"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    /// Whether this error should trigger automatic recovery (e.g., auto sign-in)
    var shouldAutoRecover: Bool {
        switch self {
        case .userAlreadyExists:
            return true
        default:
            return false
        }
    }
}

/// Error manager for parsing and converting errors to user-friendly messages
@MainActor
final class ErrorManager {
    static let shared = ErrorManager()
    
    private init() {}
    
    /// Parse a raw error into an AppError with user-friendly messaging
    func parseError(_ error: Error) -> AppError {
        let errorString = error.localizedDescription.lowercased()
        
        // Check for Supabase-specific error codes
        if errorString.contains("user_already_exists") ||
           errorString.contains("user already registered") {
            return .userAlreadyExists
        }
        
        if errorString.contains("email_not_confirmed") ||
           errorString.contains("email not confirmed") {
            return .emailNotConfirmed
        }
        
        if errorString.contains("invalid_credentials") ||
           errorString.contains("invalid credentials") ||
           errorString.contains("invalid login") {
            return .invalidCredentials
        }
        
        if errorString.contains("weak_password") ||
           errorString.contains("password is too weak") {
            return .weakPassword
        }
        
        if errorString.contains("invalid_email") ||
           errorString.contains("invalid email") {
            return .invalidEmail
        }
        
        if errorString.contains("unauthorized") ||
           errorString.contains("authentication required") {
            return .authenticationRequired
        }
        
        // Check for HTTP status codes
        if errorString.contains("http error: 401") || errorString.contains("401") {
            return .authenticationRequired
        }
        
        if errorString.contains("http error: 422") || errorString.contains("422") {
            // 422 is usually validation error, but check for specific cases
            if errorString.contains("user") || errorString.contains("email") {
                return .userAlreadyExists
            }
            return .validationError("Please check your input and try again.")
        }
        
        if errorString.contains("http error: 5") || errorString.range(of: "5[0-9]{2}", options: .regularExpression) != nil {
            return .serverError
        }
        
        if errorString.contains("timeout") || errorString.contains("timed out") {
            return .timeout
        }
        
        if errorString.contains("network") || errorString.contains("connection") {
            return .networkError
        }
        
        // Check for AuthError cases
        if let authError = error as? AuthError {
            switch authError {
            case .invalidEmail:
                return .invalidEmail
            case .passwordTooShort:
                return .weakPassword
            case .invalidUsername, .usernameTooShort, .usernameTooLong:
                return .invalidUsername
            case .notAuthenticated:
                return .authenticationRequired
            case .profileNotFound:
                return .unknown("Profile not found")
            }
        }
        
        // Default to unknown with the original error message
        return .unknown(error.localizedDescription)
    }
    
    /// Get user-friendly message from any error
    func getUserMessage(for error: Error) -> String {
        let appError = parseError(error)
        return appError.userMessage
    }
    
    /// Log error with technical details and report to analytics
    func logError(_ error: Error, context: String = "") {
        let appError = parseError(error)
        let contextString = context.isEmpty ? "" : " [\(context)]"
        print("❌ Error\(contextString): \(appError.technicalDescription)")
        print("   User Message: \(appError.userMessage)")
        
        // Report to ObservabilityManager for PostHog + Crashlytics
        ObservabilityManager.shared.reportErrorDetailed(
            error,
            errorType: String(describing: appError),
            userMessage: appError.userMessage,
            technicalDetails: appError.technicalDescription,
            context: context,
            severity: getSeverity(for: appError),
            recoverable: appError.shouldAutoRecover
        )
    }
    
    /// Determine error severity for product analytics
    private func getSeverity(for error: AppError) -> ErrorSeverity {
        switch error {
        // Critical - blocks core functionality
        case .authenticationRequired, .serverError:
            return .critical
            
        // High - blocks key features
        case .userAlreadyExists, .invalidCredentials, .networkError:
            return .high
            
        // Medium - impacts UX but has workarounds
        case .emailNotConfirmed, .weakPassword, .invalidEmail, .invalidUsername:
            return .medium
            
        // Low - validation errors, user can fix easily
        case .validationError:
            return .low
            
        // Default
        case .timeout, .unknown:
            return .medium
        }
    }
    
    /// Check if error should trigger automatic recovery
    func shouldAutoRecover(_ error: Error) -> Bool {
        let appError = parseError(error)
        return appError.shouldAutoRecover
    }
}

/// Extension to make Error parsing easier
extension Error {
    var appError: AppError {
        ErrorManager.shared.parseError(self)
    }
    
    var userMessage: String {
        ErrorManager.shared.getUserMessage(for: self)
    }
    
    var shouldAutoRecover: Bool {
        ErrorManager.shared.shouldAutoRecover(self)
    }
}

