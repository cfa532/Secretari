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
    @Published var currentUser: User? {
        didSet {
            if let count=currentUser?.username.count, count > 20 {
                loginStatus = .unregistered
            } else {
                loginStatus = .signedOut
                if userToken != nil, userToken != "" {
                    loginStatus = .signedIn
                }
            }
        }
    }
    @Published var showAlert: Bool = false
    @Published var alertItem: AlertItem?
    @Published var loginStatus: StatusLogin = .signedIn     // login status of the current user
    var userToken: String? {
        didSet {
            TokenManager.shared.saveToken(token: userToken ?? "")
            if userToken != nil, userToken != "" {
                loginStatus = .signedIn
            } else {
                loginStatus = .signedOut
                if let count=currentUser?.username.count, count > 20 {
                    // in case of annoymous user.
                    loginStatus = .unregistered
                }
           }
        }
    }
    private let keychainManager = KeychainManager.shared
    static let shared = UserManager()
    private let websocket = Websocket.shared
    private init() {}

    enum StatusLogin {
        case signedIn, signedOut, unregistered
    }
    
    func createTempUser(_ id: String) {
        // When someone starts to use the app without registration. Give it an identify.
        // Enforce registration only when user wants to subscribe.
//        Task { @MainActor in
            currentUser = User(username: id, password: "zaq1^WSX")
            print("Current", currentUser!)
            
            websocket.createTempUser(currentUser!) { dict, statusCode in
                Task { @MainActor in
                    guard let dict = dict, self.currentUser != nil, let code=statusCode, code < .failure else {
                        print("Failed to create temp user account.", self.currentUser as Any)
                        self.alertItem = AlertContext.unableToComplete
                        self.alertItem?.message = Text("Failed to create temporary account. Please try again later.")
                        self.showAlert = true
                        return
                    }
                    // update temp user with account data recieved from server.
                    self.currentUser = Utility.updateUserFromServerDict(from: dict, user: self.currentUser!)
                    
                    if !self.keychainManager.save(data: self.currentUser, for: "currentUser") {
                        print("Temp account created OK", self.currentUser as Any)
                    }
                }
//            }
        }
    }
    
    func register(_ user: User) {
        // register a user at sever when subscribe.
//        Task { @MainActor in
            websocket.registerUser(user) { dict, statusCode in
                Task { @MainActor in
                    guard let dict = dict, self.currentUser != nil, let code=statusCode, code < .failure  else {
                        print("Failed to register.", self.currentUser as Any)
                        // restore current user to original value, pop an alert and stay at registration page
                        self.currentUser = self.keychainManager.retrieve(for: "currentUser", type: User.self)
                        self.alertItem = AlertContext.unableToComplete
                        self.alertItem?.message = Text("The username is taken. Please try again.")
                        self.showAlert = true
                        return
                    }
                    // update account with token usage data from WS server
                    self.currentUser = Utility.updateUserFromServerDict(from: dict, user: self.currentUser!)
                    
                    if self.keychainManager.save(data: self.currentUser, for: "currentUser") {
                        print("Registration data received OK:", self.currentUser as Any)
                        
                        // the registration succesed. Go to login page.
//                        self.loginStatus = .signedOut
                    }
                }
//            }
        }
    }

    func login(username: String, password: String) {
        websocket.fetchToken(username: username, password: password) { dict, statusCode in
            Task { @MainActor in
                guard let dict = dict, let code=statusCode, code < .failure  else {
                    print("Failed to login.", self.currentUser as Any)
                    
                    // fetch secure token and store it on keychain
                    self.currentUser = self.keychainManager.retrieve(for: "currentUser", type: User.self)
                    
                    self.alertItem = AlertContext.unableToComplete
                    self.alertItem?.message = Text("Login failed. Please try again.")
                    self.showAlert = true
                    return
                }
                // update account with token usage data from WS server
                print("Reply to login: ", dict)
                self.currentUser = Utility.updateUserFromServerDict(from: dict["user"] as? [String: Any] ?? [:], user: self.currentUser!)
                
                let token = dict["token"] as? [String: String] ?? [:]       // {token_type:Bearer, access_token: a long string}
                self.userToken = token["access_token"]
                if self.keychainManager.save(data: self.currentUser, for: "currentUser") {
                    print("Login OK:", self.currentUser as Any)
//                    self.loginStatus = .signedIn
                }
            }
        }
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
