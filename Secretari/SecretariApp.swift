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
    @State private var errorWrapper: ErrorWrapper?
    @StateObject private var identifierManager = IdentifierManager()
    private let userManager = UserManager.shared
    private var keychainManager = KeychainManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([AudioRecord.self, Settings.self,
                             Item.self,
                            ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            TranscriptView(errorWrapper: $errorWrapper)
                .onAppear() {
                    guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else { return }
                    print(appSupportDir)
                    print("App lang:", UserDefaults.standard.stringArray(forKey: "AppleLanguages")!)
                    print("identifier: ", NSLocale.current.identifier)
 
                    // clear UserDefaults data
//                    if let bundleID = Bundle.main.bundleIdentifier {
//                        UserDefaults.standard.removePersistentDomain(forName: bundleID)
//                    }
                    
                    // check if this the first time of running. Assign an Id to user if not.
                    if identifierManager.setupIdentifier() {
                        // setup an anonymous account
                        let identifier = identifierManager.retrieveIdentifierFromKeychain() ?? UUID().uuidString
                        print("First run after launch. Init temp user account, id=", identifier)
                        userManager.createTempUser(identifier)
                    } else {
                        print("This is not the first run after launch")
                        if let user = keychainManager.retrieve(for: "currentUser", type: User.self) {
                            userManager.currentUser = user          // local user infor will be updated with each fetchToken() call
                            print("CurrentUser from keychain", userManager.currentUser! as User)
                        } else {
                            // create user account on server only when user actually send request
                            fatalError("Could not retrieve user account.")
                        }
                    }

                    // check the subscription status of the user on server. Async mode.
                    
                    let appUpdated = AppVersionManager.shared.checkIfAppUpdated()
                    if appUpdated {
                        print("App is running for the first time after an update")
                    } else {
                        print("This is not the first run after an update")
                    }
                }
                .sheet(item: $errorWrapper) {
                    //                     var records = AudioRecord.sampleData     // no need here
                } content: { wrapper in
                    ErrorView(errorWrapper: wrapper)
                }
        }
        .environment(userManager)
        .environment(identifierManager)
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

