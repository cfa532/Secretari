//
//  IdentifierManager.swift
//  Secretari
//
//  Created by 超方 on 2024/5/11.
//

import SwiftUI
import Security

class IdentifierManager: ObservableObject, Observable {
    private let firstLaunchKey = "HasLaunchedBefore"
    
    func setupIdentifier() {
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: firstLaunchKey)
        if isFirstLaunch {
            let identifier = getDeviceIdentifier()
            storeIdentifierInKeychain(identifier)
            UserDefaults.standard.set(true, forKey: firstLaunchKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func storeIdentifierInKeychain(_ identifier: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userIdentifier",
            kSecValueData as String: identifier.data(using: .utf8)!
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getDeviceIdentifier() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
    
    func retrieveIdentifierFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userIdentifier",
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == noErr {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }
}
