//
//  ErrorManager.swift
//  Pulsar
//
//  Centralized logging and user-facing messages for errors.
//

import Foundation
import OSLog

final class ErrorManager {
    static let shared = ErrorManager()
    private let logger = Logger(subsystem: "com.collinbrowse.Pulsar", category: "Error")
    
    private init() {}
    
    func logError(_ error: Error, context: String) {
        logger.error("\(context): \(error.localizedDescription)")
    }
}

extension Error {
    var userMessage: String {
        if let localized = self as? LocalizedError,
           let description = localized.errorDescription,
           !description.isEmpty {
            return description
        }
        return localizedDescription
    }
    
    /// When sign-up fails because the account already exists, callers may fall back to sign-in.
    var shouldAutoRecover: Bool {
        guard let networkError = self as? NetworkError else { return false }
        guard case .httpError(let statusCode, let message) = networkError else { return false }
        let text = (message ?? "").lowercased()
        guard statusCode == 400 || statusCode == 409 || statusCode == 422 else { return false }
        return text.contains("already") || text.contains("exists") || text.contains("registered")
    }
}
