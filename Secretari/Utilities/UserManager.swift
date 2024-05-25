//
//  UserManager.swift
//  Secretari
//
//  Created by 超方 on 2024/5/2.
//

import Foundation
import SwiftUI

class UserManager: ObservableObject, Observable {
    @MainActor @Published var currentUser: User?
//    @EnvironmentObject var webSocket: Websocket
    @EnvironmentObject var identityManager: IdentifierManager
    private let keychainManager = KeychainManager()
//    private let websocket: Websocket

//    init(websocket: Websocket) {
//        self.websocket = web
//    }
    
    func createTempUser(_ id: String) {
        // When someone starts to use the app without registration. Give it an identify.
        // Enforce registration only when user wants to subscribe.
        let webSocket = Websocket.shared
        currentUser = User(username: id, password: "zaq1^WSX")
        print(currentUser!)
        webSocket.createTempUser(currentUser!) { dict in
            guard let dict = dict, let currentUser = self.currentUser else {
                print("Cannot get user from websocket or currentUser is nil")
                return
            }
            var user = currentUser
            if let tokenCountData = dict["token_count"] as? [String: UInt] {
                user.token_count = Utility.convertDictionaryKeys(from: tokenCountData)
            }
            if let tokenUsageData = dict["token_usage"] as? [String: Float] {
                user.token_usage = Utility.convertDictionaryKeys(from: tokenUsageData)
            }
            if let currentUsageData = dict["current_usage"] as? [String: Float] {
                user.current_usage = Utility.convertDictionaryKeys(from: currentUsageData)
            }
            // save User information to keychain
            if let mid = dict["mid"] as? String {
                user.mid = mid
            }
            self.keychainManager.saveUser(user: user, account: "currentUser")
        }
    }
    
    func register() {
        // register a user at sever when subscribe.
        let webSocket = Websocket.shared
        webSocket.registerUser(self.currentUser!) { user in
            self.currentUser = user
        }
    }
    
    func loadUser(username: String?, deviceId: String?) {
        // Load user data from persistent storage (optional)
        // id can have two values. If the user never signed up, the id is device identifier. Otherwise its username
        
    }
    
    func updateSubscriptionStatus(isSubscribed: Bool) {
        guard var user = currentUser else { return }
        user.subscription = isSubscribed
        currentUser = user
    }
}

struct User :Codable {
//    let id: String // Unique identifier for the user
    var username: String
    var password: String?
    var mid: String?
    var token_count: [LLMModel: UInt]?     // gotten from server, kept locally
    var token_usage: [LLMModel: Float]?
    var current_usage: [LLMModel: Float]?   // current month usage
    var subscription: Bool = false          // Flag indicating active subscription
    var family_name: String?
    var given_name: String?
    var email: String?
    var template: [LLM: [String: String]]?

    enum CodingKeys: String, CodingKey {
        case username, mid, token_count, token_usage, current_usage, subscription, password, family_name, given_name, email, template
    }
}
