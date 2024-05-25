//
//  ContentView.swift
//  SummarySwiftData
//
//  Created by 超方 on 2024/4/5.
//

import SwiftUI
import SwiftData

struct TranscriptView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AudioRecord.recordDate, order: .reverse) var records: [AudioRecord]
    @Query private var settingsInSwiftData: [Settings]
    @Binding var errorWrapper: ErrorWrapper?
    
    @State private var settings: Settings = AppConstants.defaultSettings
    
    @State private var isRecording = false
    @State private var showDetailView = false
    @State private var showSettings = false
    
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var webSocket: Websocket

    var body: some View {
        NavigationStack {
            List {
                ForEach(records, id: \.recordDate) { item in
                    NavigationLink {
                        DetailView(record: item, isRecording: .constant(false))
                            .environment(settings)
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
                DetailView(record: AudioRecord(), isRecording: $isRecording)
            })
            .navigationDestination(isPresented: $showSettings, destination: {
                SettingsView()
                    .environment(settings)
            })
            .toolbar {
                ToolbarItem(placement: .topBarTrailing, content: {
                    NavigationLink(destination: SettingsView()) {
                        // navigationLink does not work becuase tappablePadding interfered with onTap()
                        // showSettings=true triggered navigation destination.
                        // keep navigationLnik because it change image color when tapped.
                        Image(systemName: "gearshape")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.primary)
                            .opacity(0.8)
                            .tappablePadding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)) {
                                self.showSettings = true
                            }
                    }
                })
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
            if let s = settingsInSwiftData.first {
                self.settings = s
            } else {
                // first run of the App, settings not stored by SwiftData yet.
                // the following line cannot run in App file, where Settings tyep cannot be recognized by context model
                print("Settings inited in model context")
                modelContext.insert(AppConstants.defaultSettings)
                try? modelContext.save()
                // App lang: Optional(["zh-Hant-TW", "zh-Hans-TW", "ja-TW", "en-TW"])
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: AudioRecord.self, Settings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(AudioRecord.sampleData[0])
    return TranscriptView(errorWrapper: .constant(.emptyError))
        .modelContainer(container)
    //    TranscriptView(errorWrapper: .constant(.emptyError))
    //        .modelContainer(for: [AudioRecord.self, AppSettings.self], inMemory: true)
}
