//
//  IdentifierManager.swift
//  Secretari
//
//  Created by 超方 on 2024/5/11.
//

import SwiftUI
import Security

class IdentifierManager: ObservableObject {
    private let firstLaunchKey = "HasLaunchedBefore"
    
    func setupIdentifier() -> Bool {
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
    
    func getDeviceIdentifier() -> String {
        if let id = retrieveIdentifierFromKeychain() {
            return id
        } else {
            // nothing on keychain, create one
            let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            storeIdentifierInKeychain(id)
            return id
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
