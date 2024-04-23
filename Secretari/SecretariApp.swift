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

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([AudioRecord.self, AppSettings.self,
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
                    guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else { return }
                    print(appSupportDir)
                }
                .sheet(item: $errorWrapper) {
//                     var records = AudioRecord.sampleData
                } content: { wrapper in
                    ErrorView(errorWrapper: wrapper)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
