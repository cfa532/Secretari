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
    @State private var errorWrapper: ErrorWrapper?
    @StateObject private var identifierManager = IdentifierManager()
    @StateObject private var webScoket = Websocket()
    @StateObject private var userManager = UserManager()
    @StateObject private var keychainManager = KeychainManager()

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
                .task {
                    identifierManager.setupIdentifier()
                    guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else { return }
                    print(appSupportDir)
                    print("App lang:", UserDefaults.standard.stringArray(forKey: "AppleLanguages")!)
                    print("identifier: ", NSLocale.current.identifier)
                    
                    // extract user account from keychain
                    let identifier = identifierManager.getDeviceIdentifier()
                    if let user = keychainManager.getUser(account: identifier) {
                        userManager.currentUser = user          // local user infor will be updated with each fetchToken() call
                    } else {
                        userManager.createUser(id: identifier)
                        keychainManager.saveUser(user: userManager.currentUser!, account: identifier)
                        // create user account on server only when user actually send request
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
        .environment(webScoket)
        .environment(userManager)
        .modelContainer(sharedModelContainer)
    }
}

