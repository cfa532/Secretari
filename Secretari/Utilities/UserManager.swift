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
    @Published var showAlert: Bool = false
    @Published var alertItem: AlertItem?
    @Published var loginStatus: StatusLogin = .signedOut     // login status of the current user
    var userToken: String? {
        didSet {
            if keychainManager.save(data: userToken, for: "userToken") {
                print("user token saved", userToken as Any)
            }
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
    private let websocket = Websocket.shared
    
    static let shared = UserManager()
    private init() {
        
        // There is the code code of initialization. Setup user and retrieve user data.
        
        let keychainManager = KeychainManager.shared
        let identifierManager = IdentifierManager()
        let identifier = identifierManager.getDeviceIdentifier()

        self.userToken = keychainManager.retrieve(for: "userToken", type: String.self)
        print("Access token", self.userToken as Any)
        
        if let user = keychainManager.retrieve(for: "currentUser", type: User.self) {
            // local user infor will be updated with each fetchToken() call
            if self.userToken != nil, self.userToken != "" {
                self.currentUser = user
                print("CurrentUser from keychain", self.currentUser! as User)
            } else {
                // Not login. use local temp user account.
                self.currentUser = User(username: identifier, password: "zaq1^WSX")
            }
        } else {
            // create user account on server only when user actually send request
            // fatalError("Could not retrieve user account.")
            self.createTempUser(identifier)
        }
    }
    
    enum StatusLogin {
        case signedIn, signedOut, unregistered
    }
    
    func createTempUser(_ id: String) {
        // When someone starts to use the app without registration. Give it an identify.
        // Enforce registration only when user wants to subscribe.
        self.currentUser = User(username: id, password: "zaq1^WSX")
        websocket.createTempUser(currentUser!) { dict, statusCode in
            Task { @MainActor in
                guard let dict = dict, let code=statusCode, code < .failure else {
                    print(dict as Any)
                    fatalError("Failed to create temp user account.")
                }
                // update temp user with account data recieved from server.
                self.currentUser = Utility.updateUserFromServerDict(from: dict, user: self.currentUser!)
                self.currentUser?.password = ""
                if !self.keychainManager.save(data: self.currentUser, for: "currentUser") {
                    print("Temp account created OK", self.currentUser as Any)
                }
            }
        }
    }
    
    func register(_ user: User) {
        // register a user at sever when subscribe.
        websocket.registerUser(user) { dict, statusCode in
            Task { @MainActor in
                guard let dict = dict, self.currentUser != nil, let code=statusCode, code < .failure  else {
                    print("Failed to register.", dict as Any)
                    if let dict = dict as? [String: String] {
                        self.alertItem = AlertContext.unableToComplete
                        self.alertItem?.message = Text(dict["detail"] ?? "Failed to register.")
                        self.showAlert = true
                    }
                    return
                }
                // update account with token usage data from WS server
                self.currentUser = Utility.updateUserFromServerDict(from: dict, user: self.currentUser!)
                
                // even after registration, the currentUser still use temp account, until after login.
                if self.keychainManager.save(data: self.currentUser, for: "currentUser") {
                    print("Registration data received OK:", self.currentUser as Any)
                    self.loginStatus = .signedOut
                }
            }
        }
    }
    
    func login(username: String, password: String) {
        
        // not used for now.
        
        websocket.fetchToken(username: username, password: password) { dict, statusCode in
            Task { @MainActor in
                guard let dict = dict, let code=statusCode, code < .failure  else {
                    print("Failed to login.", dict as Any)
                    self.alertItem = AlertContext.unableToComplete
                    if let dict = dict as? [String: String] {
                        self.alertItem?.message = Text(dict["detail"] ?? "Login error")
                    }
                    self.showAlert = true
                    return
                }
                // update account with token usage data from WS server
                print("Reply to login: ", dict)
                self.currentUser = Utility.updateUserFromServerDict(from: dict["user"] as? [String: Any] ?? [:], user: self.currentUser!)
                self.currentUser?.username = username
                self.currentUser?.password = ""
                let token = dict["token"] as? [String: String] ?? [:]       // {token_type:Bearer, access_token: a long string}
                self.userToken = token["access_token"]
                if self.keychainManager.save(data: self.currentUser, for: "currentUser") {
                    print("Login OK:", self.currentUser as Any)
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
