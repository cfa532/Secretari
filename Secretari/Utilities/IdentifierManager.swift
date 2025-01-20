//
//  IdentifierManager.swift
//  Secretari
//
//  Created by 超方 on 2024/5/11.
//

import SwiftUI
import Security

class IdentifierManager: ObservableObject {
    
    // Using AppStorage to persist the first launch status. Initialize some data on first launch.
    @AppStorage("HasLaunchedBefore") var isFirstLaunch: Bool = true
    
    /// Sets up the device identifier.
    /// - Returns: A boolean indicating if it's the first launch.
    func setupIdentifier() -> Bool {
        if isFirstLaunch {
            print("Launch for the first time.")
            let identifier = getDeviceIdentifier()      // make sure the identiifier is more than 20 chars long, to distinguish fromm real username.
            storeIdentifierInKeychain(identifier)
            isFirstLaunch = false
            print("Device identifier", identifier)
        }
        return isFirstLaunch
    }
    
    /// Retrieves the device identifier from the keychain or generates a new one.
    /// - Returns: The device identifier string.
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
    
    /// Stores the identifier in the keychain.
    /// - Parameter identifier: The identifier string to store.
    private func storeIdentifierInKeychain(_ identifier: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userIdentifier",
            kSecValueData as String: identifier.data(using: .utf8)!
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
    /// Retrieves the identifier from the keychain.
    /// - Returns: The identifier string if found, otherwise nil.
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

    /// Checks if the app has been updated since the last launch.
    /// - Returns: A boolean indicating if the app has been updated.
    func checkIfAppUpdated() -> Bool {
        // Get the current app version from the bundle.
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        // Get the previously stored app version from UserDefaults.
        let previousVersion = UserDefaults.standard.string(forKey: versionKey) ?? ""

        if currentVersion != previousVersion {
            UserDefaults.standard.set(currentVersion, forKey: versionKey)
            UserDefaults.standard.synchronize()
            return true // App has been updated
        }
        return false // No update detected
    }
}
