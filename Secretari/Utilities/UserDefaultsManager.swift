//
//  UserDefaultsManager.swift
//  Secretari
//
//  Created by 超方 on 2024/5/25.
//

import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard

    // Save data
    func set<T: Encodable>(_ value: T, for key: String) {
        do {
            let encoded = try JSONEncoder().encode(value)
            defaults.set(encoded, forKey: key)
        } catch {
            print("UserDefaultsManager: failed to encode value for key '\(key)':", error.logDescription)
        }
    }

    // Retrieve data
    func get<T: Decodable>(for key: String, type: T.Type) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    // Remove data
    func remove(for key: String) {
        defaults.removeObject(forKey: key)
    }
}
