//
//  KeychainStorage.swift
//  Pulsar
//
//  Secure storage for auth session so the user stays logged in across launches.
//

import Foundation
import Security

enum KeychainStorage {
    private static let service = "com.collinbrowse.Pulsar"
    private static let sessionAccount = "authSession"
    
    struct PersistedSession: Codable {
        let userId: String
        let accessToken: String
        let refreshToken: String?
    }
    
    static func saveSession(userId: String, accessToken: String, refreshToken: String?) {
        let session = PersistedSession(userId: userId, accessToken: accessToken, refreshToken: refreshToken)
        guard let data = try? JSONEncoder().encode(session) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: sessionAccount
        ]
        
        SecItemDelete(query as CFDictionary) // Remove existing so we can add
        
        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        
        SecItemAdd(addQuery as CFDictionary, nil)
    }
    
    static func loadSession() -> PersistedSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: sessionAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let session = try? JSONDecoder().decode(PersistedSession.self, from: data) else {
            return nil
        }
        
        return session
    }
    
    static func clearSession() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: sessionAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Generic string keychain (e.g. full auth session JSON)

final class KeychainManager {
    static let shared = KeychainManager()
    private let service = "com.collinbrowse.Pulsar"
    private init() {}
    
    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainManagerError.encodingFailed
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainManagerError.saveFailed(status)
        }
    }
    
    func load(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainManagerError.loadFailed(status)
        }
        return string
    }
    
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainManagerError: Error {
    case encodingFailed
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
}
