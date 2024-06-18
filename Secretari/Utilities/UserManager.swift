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
    
    private let keychainManager = KeychainManager.shared
    private let userDefaultsManager = UserDefaultsManager.shared
    private let websocket = Websocket.shared
//    private let entitlementManager = EntitlementManager()
    
    var userToken: String? {
        didSet {
            _ = keychainManager.save(data: userToken, for: "userToken")
            if userToken != nil, userToken != "" {
                loginStatus = .signedIn
            } else {
                loginStatus = .signedOut
                if let count=currentUser?.username.count, count > 20 {
                    // in case of annoymous user, with device identifier as temp username.
                    loginStatus = .unregistered
                }
            }
        }
    }
    static let shared = UserManager()
    private init() {
        // There is the core code of initialization. Setup user and retrieve user data.
                
        if let user = userDefaultsManager.get(for: "currentUser", type: User.self) {
            // local user infor will be updated with each fetchToken() call
            self.currentUser = user
            self.userToken = keychainManager.retrieve(for: "userToken", type: String.self)
            print("CurrentUser retrieved:", self.currentUser! as User, "Token=", self.userToken as Any)
        } else {
            print("First time run.")
            let identifierManager = IdentifierManager()
            let identifier = identifierManager.getDeviceIdentifier()
            self.createTempUser(identifier)
        }
    }
    
    enum StatusLogin {
        case signedIn, signedOut, unregistered
    }
    
    func persistCurrentUser() {
        self.userDefaultsManager.set(self.currentUser, for: "currentUser")
    }
    
    func createTempUser(_ id: String) {
        // When someone starts to use the app without registration. Give it an identify.
        Task { @MainActor in
            do {
                self.currentUser = User(id: id, username: id, password: "zaq1^WSX")
                if let json = try await websocket.createTempUser( self.currentUser! ) {

                    // json from server should be {token, user}
                    if let token = json["token"] as? [String: Any] {
                        self.userToken = token["access_token"] as? String
                    }
                    if let serverUser = json["user"] as? [String: Any] {
                        // update temp user with account data recieved from server.
                        self.currentUser = Utility.updateUserFromServerDict(from: serverUser, user: self.currentUser!)
                        self.currentUser?.password = ""
                        self.persistCurrentUser()
                        print("temprory user created", self.currentUser as Any)
                    }
                }
            } catch {
                fatalError("Failed to create temporary user.")
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
                self.persistCurrentUser()

                // After registration, the currentUser still use temp account, until user login.
                self.loginStatus = .signedOut
            }
        }
    }
    
    @MainActor func updateUser(_ user: User) async {
        do {
            if let json = try await websocket.updateUser(user) {
                // edit balance on local record too.
                print("User updated.", json)      // do not use it for now.
                if let email=json["email"] as? String, let fn=json["family_name"] as? String, let gn=json["given_name"] as? String {
                    self.currentUser?.email = email
                    self.currentUser?.family_name = fn
                    self.currentUser?.given_name = gn
                    self.persistCurrentUser()
                }
            }
        } catch {
            print("Error update user")
            self.alertItem = AlertContext.unableToComplete
            self.alertItem?.message = Text("Update failure")
            self.showAlert = true
        }
    }    
}
