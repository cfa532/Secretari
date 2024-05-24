//
//  UserManager.swift
//  Secretari
//
//  Created by 超方 on 2024/5/2.
//

import Foundation
import SwiftUI

class UserManager: ObservableObject, Observable {
    @Published var currentUser: User?
    @EnvironmentObject var webSocket: Websocket
    @EnvironmentObject var identityManager: IdentifierManager
//    private let websocket: Websocket

//    init(websocket: Websocket) {
//        self.websocket = web
//    }
    
    func createUser(id: String) {
        // When someone starts to use the app without registration. Give it an identify.
        // Enforce registration only when user wants to subscribe.
        currentUser = User(id: id, tokens: User.signupBonus, subscription: false)
    }
    
    func register(username: String?, password: String?) {
        // register a user at sever when subscribe.
        if username == "" {
//            identifier = identityManager.getDeviceIdentifier()
        }
    }
    
    func loadUser(username: String?, deviceId: String?) {
        // Load user data from persistent storage (optional)
        // id can have two values. If the user never signed up, the id is device identifier. Otherwise its username
//        currentUser = User(tokens: , subscription: false) // Placeholder for initial data
    }
    
    func awardSignupBonus() {
        guard var user = currentUser else { return }
        user.tokens = User.signupBonus
        currentUser = user
    }
    
    func updateSubscriptionStatus(isSubscribed: Bool) {
        guard var user = currentUser else { return }
        user.subscription = isSubscribed
        currentUser = user
    }
    
    func addTokens(amount: [LLMModel : UInt]) {
        guard var user = currentUser else { return }
        for key in amount.keys {
            user.tokens[key]! += amount[key] ?? 0
        }
        currentUser = user
    }
    
    func deductTokens(amount: [LLMModel :UInt]) {
        guard var user = currentUser else { return }
        for key in amount.keys {
            user.tokens[key] = max(user.tokens[key]! - amount[key]!, 0) // Ensure tokens don't go negative
        }
        currentUser = user
    }
}

struct User :Codable {
    let id: String // Unique identifier for the user
    var tokens: [LLMModel : UInt]
    var subscription: Bool // Flag indicating active subscription
    var username: String = ""
    var password = AppConstants.DefaultPassword
//    let deviceIdentifier: String = ""
    
    static let signupBonus :[LLMModel : UInt] = [LLMModel.GPT_3: 1000000, LLMModel.GPT_4_Turbo: 40000] // Signup bonus amount (constant)
    
    enum CodingKeys: String, CodingKey {
        case id, tokens, subscription, username, password
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(subscription, forKey: .subscription)
        try container.encode(username, forKey: .username)
        try container.encode(password, forKey: .password)
        
        var tokensContainer = container.nestedContainer(keyedBy: LLMModel.self, forKey: .tokens)
        for (key, value) in tokens {
            try tokensContainer.encode(value, forKey: key)
        }
    }
}

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
