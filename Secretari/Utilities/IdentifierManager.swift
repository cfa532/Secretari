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
    
    func setupIdentifier() -> Bool? {
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: firstLaunchKey)
        if isFirstLaunch {
            let identifier = getDeviceIdentifier()      // make sure the identiifier is more than 20 chars long, to distinguish fromm real username.
            storeIdentifierInKeychain(identifier)
            UserDefaults.standard.set(true, forKey: firstLaunchKey)
            UserDefaults.standard.synchronize()
            print("Device identifier", identifier)
        }
        return isFirstLaunch
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
    
    private func retrieveIdentifierFromKeychain() -> String? {
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

class AppVersionManager {
    static let shared = AppVersionManager()
    private let versionKey = "appVersion"

    func checkIfAppUpdated() -> Bool {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let previousVersion = UserDefaults.standard.string(forKey: versionKey) ?? ""

        if currentVersion != previousVersion {
            UserDefaults.standard.set(currentVersion, forKey: versionKey)
            UserDefaults.standard.synchronize()
            return true // App has been updated
        }
        return false // No update detected
    }
}

class TokenManager {
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
