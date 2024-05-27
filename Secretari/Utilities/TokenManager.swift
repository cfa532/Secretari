//
//  TokenManager.swift
//  Secretari
//
//  Created by 超方 on 2024/5/27.
//

import Foundation

class TokenManager {
    static let shared = TokenManager()
    private init() {}
    
    func saveToken(token: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userToken",
            kSecValueData as String: token.data(using: .utf8)!
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userToken",
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &item) == noErr {
            if let data = item as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }
    
    func isTokenExpired(token: String) -> Bool {
        let segments = token.split(separator: ".")
        if segments.count == 3, let payloadData = Data(base64Encoded: String(segments[1])),
           let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
           let exp = json["exp"] as? Double {
            return Date(timeIntervalSince1970: exp) < Date()
        }
        return true
    }
}
