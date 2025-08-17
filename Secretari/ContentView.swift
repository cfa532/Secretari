//
//  ContentView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AudioRecord.recordDate, order: .reverse) var records: [AudioRecord]
    
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionsManager: SubscriptionsManager
    @EnvironmentObject private var speechRecognizer: SpeechRecognizer
    
    @State private var isRecording = false
    @State private var showDetailView = false
    
    private var loginStatus: LocalizedStringKey {
        switch userManager.loginStatus {
        case .signedIn:
            return LocalizedStringKey("Account")
        case .signedOut:
            return LocalizedStringKey("Login")
        case .unregistered:
            return LocalizedStringKey("Register")
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(records, id: \.recordDate) { item in
                    NavigationLink {
                        DetailView(isRecording: .constant(false), record: item)
                    } label: {
                        SummaryRowView(record: item)
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { idx in
                        modelContext.delete(records[idx])
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("Records"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showDetailView, destination: {
                DetailView(isRecording: $isRecording, record: AudioRecord())
            })
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        NavigationLink(destination: SettingsView()) {
                            Label("Settings", systemImage: "gearshape")
                        }
                        
                        NavigationLink {
                            AccountView()
                        } label: {
                            Label(
                                title: { Text(self.loginStatus) },
                                icon: { Image(systemName: "square.and.pencil") }
                            )
                        }
                        NavigationLink {
                            StoreFrontView()
                        } label: {
                            Label("Purchase", systemImage: "lightbulb.max")
                        }
                        NavigationLink {
                            HelpView()
                        } label: {
                            Label("Help", systemImage: "questionmark.circle")
                        }
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 23, height: 23)
                            .foregroundColor(.primary)
                            .opacity(0.7)
                            .padding(7)
                            .contentShape(Rectangle())      // increase tappable area
                    }
                }
            }
            .onAppear(perform: {
                if let _ = userManager.userToken {
                    userManager.loginStatus = .signedIn
                }
            })
            .overlay(content: {
                if records.isEmpty {
                    ContentUnavailableView(label: {
                        Label("No records", systemImage: "list.bullet.rectangle.portrait")
                    }, description: {
                        Text(LocalizedStringKey("Push the START button to record your own speech. A summary will be generated automatically after STOP button is pushed."))
                        Text(LocalizedStringKey("First make sure to select the right language for recognition in setting ⚙️ Otherwise the built-in speech recognizer cannot work properly."))
                            .foregroundColor(.accentColor)
                            .fontWeight(.bold)
                    })
                }
            })

            
            Button(action: {
                self.isRecording = true
                self.showDetailView = true        // active navigation link to detail view
                Task { @MainActor in
                    let settings = SettingsManager.shared.getSettings()
                    self.speechRecognizer.transcript = ""
                    await self.speechRecognizer.setup(locale: settings.selectedLocale.rawValue)
                    await self.speechRecognizer.startTranscribing()
                }
            }, label: {
                Text(LocalizedStringKey("Start"))
                    .padding(24)
                    .font(.title)
                    .background(Color.white)
                    .foregroundColor(.red)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            })
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: AudioRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(AudioRecord.sampleData[0])
    return ContentView()
        .modelContainer(container)
        .environmentObject(UserManager.shared)
        .environmentObject(SpeechRecognizer())
}
