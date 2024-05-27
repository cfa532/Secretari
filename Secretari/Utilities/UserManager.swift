//
//  UserManager.swift
//  Secretari
//
//  Created by 超方 on 2024/5/2.
//

import Foundation
import SwiftUI

//@MainActor
class UserManager: ObservableObject, Observable {
    @Published var currentUser: User?
    private let keychainManager = KeychainManager.shared
    
    static let shared = UserManager()
    private init() {
        
    }
    //    init(websocket: Websocket) {
    //        self.websocket = web
    //    }
    
    func createTempUser(_ id: String) {
        // When someone starts to use the app without registration. Give it an identify.
        // Enforce registration only when user wants to subscribe.
        let webSocket = Websocket.shared
        Task { @MainActor in
            currentUser = User(username: id, password: "zaq1^WSX")
            print("Current", currentUser!)
            
            webSocket.createTempUser(self.currentUser!) { dict in
                Task { @MainActor in
                    guard let dict = dict, self.currentUser != nil else {
                        print("Cannot get user from websocket or currentUser is nil")
                        return
                    }
                    self.currentUser = Utility.convertDictionaryToUser(from: dict, user: self.currentUser!)
                    
                    if !self.keychainManager.save(data: self.currentUser, for: "currentUser") {
                        print("Failed to save user in Keychain.", self.currentUser as Any)
                    } else {
                        print("Temp account created OK", self.currentUser as Any)
                    }
                }
            }
        }
    }
    
    func register(_ user: User) {
        // register a user at sever when subscribe.
        let webSocket = Websocket.shared
        Task { @MainActor in
            webSocket.registerUser(user) { dict in
                Task { @MainActor in
                    guard let dict = dict, self.currentUser != nil else {
                        print("Failed to register.", self.currentUser as Any)
                        // restore current user to original value, pop an alert and stay at registration page
                        UserManager.shared.currentUser = self.keychainManager.retrieve(for: "currentUser", type: User.self)
                        return
                    }
                    // update account with token usage data from WS server
                    self.currentUser = Utility.convertDictionaryToUser(from: dict, user: self.currentUser!)
                    if !self.keychainManager.save(data: self.currentUser, for: "currentUser") {
                        print("Registration data received:", self.currentUser as Any)
                    }
                }
            }
        }
    }
    
    func loadUser(username: String?, deviceId: String?) {
        // Load user data from persistent storage (optional)
        // id can have two values. If the user never signed up, the id is device identifier. Otherwise its username
        
    }
    
    func updateSubscriptionStatus(isSubscribed: Bool) {
        guard var user = self.currentUser else { return }
        user.subscription = isSubscribed
        self.currentUser = user
    }
}

struct User :Codable {
    //    let id: String // Unique identifier for the user
    var username: String
    var password: String
    var mid: String?
    var token_count: [LLMModel: UInt]?     // gotten from server, kept locally
    var token_usage: [LLMModel: Double]?
    var current_usage: [LLMModel: Double]?   // current month usage
    var subscription: Bool = false          // Flag indicating active subscription
    var family_name: String?
    var given_name: String?
    var email: String?
    var template: [LLM: [String: String]]?
    
    enum CodingKeys: String, CodingKey {
        case username, mid, token_count, token_usage, current_usage, subscription, password, family_name, given_name, email, template
    }
}
