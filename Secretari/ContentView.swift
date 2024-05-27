//
//  ContentView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/26.
//

//
//  ContentView.swift
//  SummarySwiftData
//
//  Created by 超方 on 2024/4/5.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AudioRecord.recordDate, order: .reverse) var records: [AudioRecord]
    @Binding var errorWrapper: ErrorWrapper?
    
    @State private var settings: Settings = SettingsManager.shared.getSettings()
    @State private var isRecording = false
    @State private var showDetailView = false
    @State private var showSettings = false
    
    private let userManager = UserManager.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(records, id: \.recordDate) { item in
                    NavigationLink {
                        DetailView(isRecording: .constant(false), record: item, settings: $settings)
                    } label: {
                        SummaryRowView(record: item, promptType: settings.promptType)
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { idx in
                        modelContext.delete(records[idx])
                    }
                }
            }
            .overlay(content: {
                if records.isEmpty {
                    ContentUnavailableView(label: {
                        Label("No records", systemImage: "list.bullet.rectangle.portrait")
                    }, description: {
                        Text("Push the START button to record your own speech. A summary will be generated automatically after STOP button is pushed.")
                        Text("First make sure to select the right language for recognition in setting ⚙️ Otherwise the built-in speech recognizer cannot work properly.")
                            .foregroundColor(.accentColor)
                            .fontWeight(.bold)
                    })
                }
            })
            .navigationTitle("Records")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showDetailView, destination: {
                DetailView(isRecording: $isRecording, record: AudioRecord(), settings: $settings)
            })
            .navigationDestination(isPresented: $showSettings, destination: {
                // navigate to settingsView is triggered by tapping button with enlarged tappable area.
                SettingsView(settings: $settings)
            })
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        NavigationLink(destination: SettingsView(settings: $settings)) {
                            Label("Settings", systemImage: "gearshape")
                        }
                        NavigationLink {
                            AccountView()
                        } label: {
                            Label(
                                title: { Text(loginMenuBar()) },
                                icon: { Image(systemName: "square.and.pencil") }
                            )
                        }

                        
//                        NavigationLink(destination: AccountView) {
//                            Label(title: {
//                                userManager.currentUser?.username.count > 20 ? "Login" : "Register"
//                            }, icon: {
//                                "pencil.and.scribble")
//                            }
//                        }
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.primary)
                            .opacity(0.7)
                    }

                }
//                ToolbarItem(placement: .topBarTrailing, content: {
//                    NavigationLink(destination: SettingsView(settings: $settings)) {
//                        // navigationLink does not work becuase tappablePadding interfered with onTap()
//                        // showSettings=true triggered navigation destination.
//                        // keep navigationLnik because it change image color when tapped.
//                        Image(systemName: "person.fill.turn.down")
//                            .resizable()
//                            .frame(width: 20, height: 20)
//                            .foregroundColor(.primary)
//                            .opacity(0.8)
//                            .tappablePadding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)) {
//                                self.showSettings = true
//                            }
//                    }
//                })
            }
            
            Button(action: {
                self.isRecording = true
                self.showDetailView = true        // active navigation link to detail view
            }, label: {
                Text("Start")
                    .padding(24)
                    .font(.title)
                    .background(Color.white)
                    .foregroundColor(.red)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            })
        }
        .onAppear {
        }
    }
    
    private func loginMenuBar() -> String {
        if let user=UserManager.shared.currentUser, user.username.count > 20 {
            // a temp default account with system generated name
            return "Register"
        }
        return "Login"
    }
}

#Preview {
    let container = try! ModelContainer(for: AudioRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(AudioRecord.sampleData[0])
    return ContentView(errorWrapper: .constant(.emptyError))
        .modelContainer(container)
    //    TranscriptView(errorWrapper: .constant(.emptyError))
    //        .modelContainer(for: [AudioRecord.self, AppSettings.self], inMemory: true)
}
