//
//  SecretariApp.swift
//  Secretari
//
//  Created by 超方 on 2024/4/19.
//

import SwiftUI
import SwiftData

@main
struct SecretariApp: App {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) private var modelContext
    @StateObject private var userManager = UserManager.shared
    
    @StateObject private var entitlementManager: EntitlementManager
    @StateObject private var subscriptionsManager: SubscriptionsManager
    
    init() {
        let entitlementManager = EntitlementManager()
        let subscriptionsManager = SubscriptionsManager(entitlementManager: entitlementManager)
        
        self._entitlementManager = StateObject(wrappedValue: entitlementManager)
        self._subscriptionsManager = StateObject(wrappedValue: subscriptionsManager)
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([AudioRecord.self, /*Settings.self,*/ Item.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else { return }
                    print(appSupportDir)
                    print("App lang:", UserDefaults.standard.stringArray(forKey: "AppleLanguages")!)
                    print("identifier: ", NSLocale.current.identifier)
                    
                    // clear user data from UserDefaults and Keychain
//                    if let bundleID = Bundle.main.bundleIdentifier {
//                        let keychainManager = KeychainManager.shared
//                        UserDefaults.standard.removePersistentDomain(forName: bundleID)
//                        keychainManager.delete(for: "userIdentifier")
//                        keychainManager.delete(for: "userToken")
//                        keychainManager.delete(for: "currentUser")
//                    }
//                    let identifierManager = IdentifierManager()
                    
                    // check if this the first time of running. Assign an ID to user if not.
//                    if identifierManager.setupIdentifier() {
                        // setup an anonymous account
//                        let identifier = identifierManager.retrieveIdentifierFromKeychain() ?? UUID().uuidString
//                        userManager.createTempUser(identifier)
//                        print("First run after launch. Init temp user account, id=", identifier)
//                    } else {
//                        print("This is not the first run after launch")
//                        userManager.userToken = KeychainManager.shared.retrieve(for: "userToken", type: String.self)
//                        if let user = keychainManager.retrieve(for: "currentUser", type: User.self) {
//                            userManager.currentUser = user          // local user infor will be updated with each fetchToken() call
//                            print("CurrentUser from keychain", userManager.currentUser! as User)
//                        } else {
//                            // create user account on server only when user actually send request
//                            fatalError("Could not retrieve user account.")
//                        }
//                    }
                    let appUpdated = AppVersionManager.shared.checkIfAppUpdated()
                    if appUpdated {
                        print("App is running for the first time after an update")
                    } else {
                        print("This is not the first run after an update")
                    }
                }
                .alert("Error", isPresented: $userManager.showAlert, presenting: userManager.alertItem) { _ in
                } message: { alertItem in
                    userManager.alertItem?.message
                }
                .environmentObject(userManager)
                .environmentObject(entitlementManager)
                .environmentObject(subscriptionsManager)
                .task {
                    // check the subscription status of the user on server. Async mode.
                    await subscriptionsManager.updatePurchasedProducts()
                }

        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase, { oldPhase, newPhase in
            print("scene phase \(newPhase)")
            if newPhase == .background {
                // add notification to center
                let content = UNMutableNotificationContent()
                content.title = "SecretAi listening"
                content.body = "Background speech recognization in progress."
                content.sound = UNNotificationSound.default
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let uuidString = UUID().uuidString
                let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
                
                let center = UNUserNotificationCenter.current()
                center.add(request) { (error) in
                    if error != nil {
                        print("Error adding to notification center \(String(describing: error))")
                    }
                }
            }
        })
    }
}
