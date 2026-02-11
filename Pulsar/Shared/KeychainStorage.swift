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
    
    static func loadSession() -> (userId: String, accessToken: String, refreshToken: String?)? {
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
        
        return (session.userId, session.accessToken, session.refreshToken)
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
