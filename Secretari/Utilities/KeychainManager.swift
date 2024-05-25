//
//  KeychainManager.swift
//  Secretari
//
//  Created by 超方 on 2024/5/25.
//

import Foundation

class KeychainManager :ObservableObject {
    func saveUser(user: User, account: String) {
        do {
            let jsonData = try JSONEncoder().encode(user)
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account,
                kSecValueData as String: jsonData
            ]
            SecItemAdd(query as CFDictionary, nil)
        } catch {
            print("Error encoding User: \(error)")
        }
    }

    func getUser(account: String) -> User? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == noErr, let data = item as? Data {
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                return user
            } catch {
                print("Error decoding User from JSON: \(error)")
            }
        }
        return nil
    }
}
