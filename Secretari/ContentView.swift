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
    @StateObject private var userManager = UserManager.shared
    
    @State private var isRecording = false
    @State private var showDetailView = false
    
    private var loginStatus: String {
        switch userManager.loginStatus {
        case .signedIn:
            return "Account"
        case .signedOut:
            return "Login"
        case .unregistered:
            return "Register"
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
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.primary)
                            .opacity(0.7)
                            .padding()
                            .contentShape(Rectangle())      // increase tappable area
                    }
                    
                }
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
    }
}

#Preview {
    let container = try! ModelContainer(for: AudioRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(AudioRecord.sampleData[0])
    return ContentView()
        .modelContainer(container)
    //    TranscriptView(errorWrapper: .constant(.emptyError))
    //        .modelContainer(for: [AudioRecord.self, AppSettings.self], inMemory: true)
}
