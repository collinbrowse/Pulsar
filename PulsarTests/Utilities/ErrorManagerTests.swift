//
//  ErrorManagerTests.swift
//  PulsarTests
//
//  Created on 11/24/25.
//

import Foundation
@testable import Pulsar
import Testing

@Suite("ErrorManager Tests")
@MainActor
// swiftlint:disable:next type_body_length
struct ErrorManagerTests {
    // MARK: - parseError Tests
    
    @Test("Parse user_already_exists error")
    func testParseUserAlreadyExists() {
        let error = NSError(domain: "test", code: 422, userInfo: [
            NSLocalizedDescriptionKey: "user_already_exists"
        ])
        
        let appError = ErrorManager.shared.parseError(error)
        
        if case .userAlreadyExists = appError {
            // Success
        } else {
            Issue.record("Expected .userAlreadyExists, got \(appError)")
        }
    }
    
    @Test("Parse email_not_confirmed error")
    func testParseEmailNotConfirmed() {
        let error = NSError(domain: "test", code: 400, userInfo: [
            NSLocalizedDescriptionKey: "email_not_confirmed"
        ])
        
        let appError = ErrorManager.shared.parseError(error)
        
        if case .emailNotConfirmed = appError {
            // Success
        } else {
            Issue.record("Expected .emailNotConfirmed, got \(appError)")
        }
    }
    
    @Test("Parse invalid_credentials error")
    func testParseInvalidCredentials() {
        let error = NSError(domain: "test", code: 401, userInfo: [
            NSLocalizedDescriptionKey: "invalid_credentials"
        ])
        
        let appError = ErrorManager.shared.parseError(error)
        
        if case .invalidCredentials = appError {
            // Success
        } else {
            Issue.record("Expected .invalidCredentials, got \(appError)")
        }
    }
    
    @Test("Parse weak_password error")
    func testParseWeakPassword() {
        let error = NSError(domain: "test", code: 400, userInfo: [
            NSLocalizedDescriptionKey: "weak_password"
        ])
        
        let appError = ErrorManager.shared.parseError(error)
        
        if case .weakPassword = appError {
            // Success
        } else {
            Issue.record("Expected .weakPassword, got \(appError)")
        }
    }
    
    @Test("Parse invalid_email error")
    func testParseInvalidEmail() {
        let error = NSError(domain: "test", code: 400, userInfo: [
            NSLocalizedDescriptionKey: "invalid_email"
        ])
        
        let appError = ErrorManager.shared.parseError(error)
        
        if case .invalidEmail = appError {
            // Success
        } else {
            Issue.record("Expected .invalidEmail, got \(appError)")
        }
    }
    
    @Test("Parse HTTP 401 error")
    func testParseHTTP401() {
        let error = NSError(domain: "test", code: 401, userInfo: [
            NSLocalizedDescriptionKey: "HTTP error: 401"
        ])
        
        let appError = ErrorManager.shared.parseError(error)
        
        if case .authenticationRequired = appError {
            // Success
        } else {
            Issue.record("Expected .authenticationRequired, got \(appError)")
        }
    }
    
    @Test("Parse HTTP 422 error")
    func testParseHTTP422() {
        let error = NSError(domain: "test", code: 422, userInfo: [
            NSLocalizedDescriptionKey: "HTTP error: 422"
        ])
        
        let appError = ErrorManager.shared.parseError(error)
        
        // 422 without user/email context should be validationError
        if case .validationError = appError {
            // Success
        } else {
            Issue.record("Expected .validationError, got \(appError)")
        }
    }
    
    @Test("Parse HTTP 422 with user context")
    func testParseHTTP422WithUser() {
        let error = NSError(domain: "test", code: 422, userInfo: [
            NSLocalizedDescriptionKey: "HTTP error: 422 user already exists"
        ])
        
        let appError = ErrorManager.shared.parseError(error)
        
        if case .userAlreadyExists = appError {
            // Success
        } else {
            Issue.record("Expected .userAlreadyExists, got \(appError)")
        }
    }
    
    @Test("Parse HTTP 5xx server error")
    func testParseHTTP5xx() {
        let error = NSError(domain: "test", code: 500, userInfo: [
            NSLocalizedDescriptionKey: "HTTP error: 500"
        ])
        
        let appError = ErrorManager.shared.parseError(error)
        
        if case .serverError = appError {
            // Success
        } else {
            Issue.record("Expected .serverError, got \(appError)")
        }
    }
    
    @Test("Parse timeout error")
    func testParseTimeout() {
        let error = NSError(domain: "test", code: -1001, userInfo: [
            NSLocalizedDescriptionKey: "Request timed out"
        ])
        
        let appError = ErrorManager.shared.parseError(error)
        
        if case .timeout = appError {
            // Success
        } else {
            Issue.record("Expected .timeout, got \(appError)")
        }
    }
    
    @Test("Parse network error")
    func testParseNetworkError() {
        let error = NSError(domain: "test", code: -1009, userInfo: [
            NSLocalizedDescriptionKey: "Network connection error"
        ])
        
        let appError = ErrorManager.shared.parseError(error)
        
        if case .networkError = appError {
            // Success
        } else {
            Issue.record("Expected .networkError, got \(appError)")
        }
    }
    
    @Test("Parse AuthError.invalidEmail")
    func testParseAuthErrorInvalidEmail() {
        let error = AuthError.invalidEmail
        let appError = ErrorManager.shared.parseError(error)
        
        if case .invalidEmail = appError {
            // Success
        } else {
            Issue.record("Expected .invalidEmail, got \(appError)")
        }
    }
    
    @Test("Parse AuthError.passwordTooShort")
    func testParseAuthErrorPasswordTooShort() {
        let error = AuthError.passwordTooShort
        let appError = ErrorManager.shared.parseError(error)
        
        if case .weakPassword = appError {
            // Success
        } else {
            Issue.record("Expected .weakPassword, got \(appError)")
        }
    }
    
    @Test("Parse AuthError.invalidUsername")
    func testParseAuthErrorInvalidUsername() {
        let error = AuthError.invalidUsername
        let appError = ErrorManager.shared.parseError(error)
        
        if case .invalidUsername = appError {
            // Success
        } else {
            Issue.record("Expected .invalidUsername, got \(appError)")
        }
    }
    
    @Test("Parse AuthError.usernameTooShort")
    func testParseAuthErrorUsernameTooShort() {
        let error = AuthError.usernameTooShort
        let appError = ErrorManager.shared.parseError(error)
        
        if case .invalidUsername = appError {
            // Success
        } else {
            Issue.record("Expected .invalidUsername, got \(appError)")
        }
    }
    
    @Test("Parse AuthError.usernameTooLong")
    func testParseAuthErrorUsernameTooLong() {
        let error = AuthError.usernameTooLong
        let appError = ErrorManager.shared.parseError(error)
        
        if case .invalidUsername = appError {
            // Success
        } else {
            Issue.record("Expected .invalidUsername, got \(appError)")
        }
    }
    
    @Test("Parse AuthError.notAuthenticated")
    func testParseAuthErrorNotAuthenticated() {
        let error = AuthError.notAuthenticated
        let appError = ErrorManager.shared.parseError(error)
        
        if case .authenticationRequired = appError {
            // Success
        } else {
            Issue.record("Expected .authenticationRequired, got \(appError)")
        }
    }
    
    @Test("Parse AuthError.profileNotFound")
    func testParseAuthErrorProfileNotFound() {
        let error = AuthError.profileNotFound
        let appError = ErrorManager.shared.parseError(error)
        
        if case .unknown(let message) = appError {
            #expect(message == "Profile not found")
        } else {
            Issue.record("Expected .unknown with 'Profile not found', got \(appError)")
        }
    }
    
    @Test("Parse unknown error")
    func testParseUnknownError() {
        let error = NSError(domain: "test", code: 999, userInfo: [
            NSLocalizedDescriptionKey: "Some unexpected error"
        ])
        
        let appError = ErrorManager.shared.parseError(error)
        
        if case .unknown(let message) = appError {
            #expect(message == "Some unexpected error")
        } else {
            Issue.record("Expected .unknown, got \(appError)")
        }
    }
    
    // MARK: - getUserMessage Tests
    
    @Test("Get user message for userAlreadyExists")
    func testGetUserMessageUserAlreadyExists() {
        let error = AppError.userAlreadyExists
        let message = ErrorManager.shared.getUserMessage(for: error)
        
        #expect(message == "An account with this email already exists. Signing you in...")
    }
    
    @Test("Get user message for invalidCredentials")
    func testGetUserMessageInvalidCredentials() {
        let error = AppError.invalidCredentials
        let message = ErrorManager.shared.getUserMessage(for: error)
        
        #expect(message == "Incorrect email or password. Please try again.")
    }
    
    @Test("Get user message for validationError")
    func testGetUserMessageValidationError() {
        let error = AppError.validationError("Custom validation message")
        let message = ErrorManager.shared.getUserMessage(for: error)
        
        #expect(message == "Custom validation message")
    }
    
    @Test("Get user message for unknown error")
    func testGetUserMessageUnknown() {
        let error = AppError.unknown("Technical error details")
        let message = ErrorManager.shared.getUserMessage(for: error)
        
        #expect(message == "Something went wrong. Please try again.")
    }
    
    // MARK: - shouldAutoRecover Tests
    
    @Test("userAlreadyExists should auto recover")
    func testShouldAutoRecoverUserAlreadyExists() {
        let error = AppError.userAlreadyExists
        let shouldRecover = ErrorManager.shared.shouldAutoRecover(error)
        
        #expect(shouldRecover == true)
    }
    
    @Test("invalidCredentials should not auto recover")
    func testShouldAutoRecoverInvalidCredentials() {
        let error = AppError.invalidCredentials
        let shouldRecover = ErrorManager.shared.shouldAutoRecover(error)
        
        #expect(shouldRecover == false)
    }
    
    // MARK: - Error Extension Tests
    
    @Test("Error extension appError property")
    func testErrorExtensionAppError() {
        let error = AppError.invalidEmail
        let appError = error.appError
        
        if case .invalidEmail = appError {
            // Success
        } else {
            Issue.record("Expected .invalidEmail, got \(appError)")
        }
    }
    
    @Test("Error extension userMessage property")
    func testErrorExtensionUserMessage() {
        let error = AppError.weakPassword
        let message = error.userMessage
        
        #expect(message == "Password must be at least 8 characters long.")
    }
    
    @Test("Error extension shouldAutoRecover property")
    func testErrorExtensionShouldAutoRecover() {
        let error = AppError.userAlreadyExists
        let shouldRecover = error.shouldAutoRecover
        
        #expect(shouldRecover == true)
    }
    
    // MARK: - AppError userMessage Tests
    
    @Test("AppError.userAlreadyExists userMessage")
    func testAppErrorUserMessageUserAlreadyExists() {
        let error = AppError.userAlreadyExists
        #expect(error.userMessage == "An account with this email already exists. Signing you in...")
    }
    
    @Test("AppError.emailNotConfirmed userMessage")
    func testAppErrorUserMessageEmailNotConfirmed() {
        let error = AppError.emailNotConfirmed
        #expect(error.userMessage == "Please confirm your email address before signing in.")
    }
    
    @Test("AppError.invalidCredentials userMessage")
    func testAppErrorUserMessageInvalidCredentials() {
        let error = AppError.invalidCredentials
        #expect(error.userMessage == "Incorrect email or password. Please try again.")
    }
    
    @Test("AppError.weakPassword userMessage")
    func testAppErrorUserMessageWeakPassword() {
        let error = AppError.weakPassword
        #expect(error.userMessage == "Password must be at least 8 characters long.")
    }
    
    @Test("AppError.invalidEmail userMessage")
    func testAppErrorUserMessageInvalidEmail() {
        let error = AppError.invalidEmail
        #expect(error.userMessage == "Please enter a valid email address.")
    }
    
    @Test("AppError.invalidUsername userMessage")
    func testAppErrorUserMessageInvalidUsername() {
        let error = AppError.invalidUsername
        #expect(error.userMessage == "Username must be 3-30 characters and contain only letters, numbers, hyphens, and underscores.")
    }
    
    @Test("AppError.authenticationRequired userMessage")
    func testAppErrorUserMessageAuthenticationRequired() {
        let error = AppError.authenticationRequired
        #expect(error.userMessage == "Please sign in to continue.")
    }
    
    @Test("AppError.networkError userMessage")
    func testAppErrorUserMessageNetworkError() {
        let error = AppError.networkError
        #expect(error.userMessage == "Unable to connect. Please check your internet connection.")
    }
    
    @Test("AppError.serverError userMessage")
    func testAppErrorUserMessageServerError() {
        let error = AppError.serverError
        #expect(error.userMessage == "Our servers are experiencing issues. Please try again later.")
    }
    
    @Test("AppError.timeout userMessage")
    func testAppErrorUserMessageTimeout() {
        let error = AppError.timeout
        #expect(error.userMessage == "Request timed out. Please try again.")
    }
    
    @Test("AppError.validationError userMessage")
    func testAppErrorUserMessageValidationError() {
        let error = AppError.validationError("Custom message")
        #expect(error.userMessage == "Custom message")
    }
    
    @Test("AppError.unknown userMessage")
    func testAppErrorUserMessageUnknown() {
        let error = AppError.unknown("Technical details")
        #expect(error.userMessage == "Something went wrong. Please try again.")
    }
    
    // MARK: - AppError technicalDescription Tests
    
    @Test("AppError.userAlreadyExists technicalDescription")
    func testAppErrorTechnicalDescriptionUserAlreadyExists() {
        let error = AppError.userAlreadyExists
        #expect(error.technicalDescription == "User already exists (422: user_already_exists)")
    }
    
    @Test("AppError.validationError technicalDescription")
    func testAppErrorTechnicalDescriptionValidationError() {
        let error = AppError.validationError("Test message")
        #expect(error.technicalDescription == "Validation error: Test message")
    }
    
    @Test("AppError.unknown technicalDescription")
    func testAppErrorTechnicalDescriptionUnknown() {
        let error = AppError.unknown("Test error")
        #expect(error.technicalDescription == "Unknown error: Test error")
    }
    
    // MARK: - AppError shouldAutoRecover Tests
    
    @Test("AppError.userAlreadyExists shouldAutoRecover")
    func testAppErrorShouldAutoRecoverUserAlreadyExists() {
        let error = AppError.userAlreadyExists
        #expect(error.shouldAutoRecover == true)
    }
    
    @Test("AppError.invalidCredentials shouldAutoRecover")
    func testAppErrorShouldAutoRecoverInvalidCredentials() {
        let error = AppError.invalidCredentials
        #expect(error.shouldAutoRecover == false)
    }
    
    @Test("AppError.networkError shouldAutoRecover")
    func testAppErrorShouldAutoRecoverNetworkError() {
        let error = AppError.networkError
        #expect(error.shouldAutoRecover == false)
    }
}
