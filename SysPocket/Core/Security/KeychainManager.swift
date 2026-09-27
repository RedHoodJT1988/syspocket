//
//  KeychainManager.swift
//  SysPocket
//
//  Created by Jonathan Reeves on 9/26/26.
//

import Foundation
import Security

enum KeychainError: Error {
    case duplicateEntry
    case unknown(OSStatus)
    case itemNotFound
    case invalidData
}

actor KeychainManager {
    
    // A shared instance to access the actor
    static let shared = KeychainManager()
    
    // Private initializer prevents creating multiple instances
    private init() {}
    
    func save(token: String, forKey key: String) throws {
        guard let data = token.data(using: .utf8) else { throw KeychainError.invalidData }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            try update(token: token, forKey: key)
        } else if status != errSecSuccess {
            throw KeychainError.unknown(status)
        }
    }
    
    func getToken(forKey key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess else {
            throw status == errSecItemNotFound ? KeychainError.itemNotFound : KeychainError.unknown(status)
        }
        
        guard let retrievedData = dataTypeRef as? Data,
              let token = String(data: retrievedData, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return token
    }
    
    private func update(token: String, forKey key: String) throws {
        guard let data = token.data(using: .utf8) else { throw KeychainError.invalidData }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let attributesToUpdate: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        
        guard status == errSecSuccess else { throw KeychainError.unknown(status) }
    }
    
    func deleteToken(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError.unknown(status) }
    }
}
