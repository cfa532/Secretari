//
//  KeychainManager.swift
//  Secretari
//
//  Created by 超方 on 2024/5/25.
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private init() {
    }
    
    func save<T: Codable>(data: T, for key: String) -> Bool {
        guard let encodedData = encode(data) else {
            print("Failed to encode data")
            return false
        }
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: encodedData
        ] as [String: Any]

        SecItemDelete(query as CFDictionary) // Remove any existing item with the same key
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func retrieve<T: Codable>(for key: String, type: T.Type) -> T? {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return decode(data: data, type: type)
    }

    func delete(for key: String) -> Bool {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ] as [String: Any]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }

    private func encode<T: Codable>(_ value: T) -> Data? {
        return try? JSONEncoder().encode(value)
    }

    private func decode<T: Codable>(data: Data, type: T.Type) -> T? {
        return try? JSONDecoder().decode(type, from: data)
    }
}
