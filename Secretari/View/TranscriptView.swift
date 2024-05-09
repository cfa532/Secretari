//
//  ContentView.swift
//  SummarySwiftData
//
//  Created by 超方 on 2024/4/5.
//

import SwiftUI
import SwiftData

struct TranscriptView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @Query(sort: \AudioRecord.recordDate, order: .reverse) var records: [AudioRecord]
    @Binding var errorWrapper: ErrorWrapper?
    
    @State private var isRecording = false
    @State private var showDetailView = false
    
    //    @State private var curRecord: AudioRecord?    // create an empty new audio record
    //    @State private var selectedLocale: RecognizerLocale = AppConstants.defaultSettings.selectedLocale
    //    @State var showDetailView = false
    
    //    @StateObject private var websocket = Websocket()
    //    @StateObject private var recorderTimer = RecorderTimer()
    //    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(records, id: \.recordDate) { item in
                    NavigationLink {
                        DetailView(record: item, isRecording: .constant(false))
                    } label: {
                        SummaryRowView(record: item, promptType: settings[0].promptType)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing, content: {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.primary)
                            .opacity(0.8)
                    }
                })
            }
            .task {
                if settings.isEmpty {
                    // first run of the App, settings not stored by SwiftData yet.
                    // get system language name in user's system language
                    modelContext.insert(AppConstants.defaultSettings)
                    try? modelContext.save()
                    // App lang: Optional(["zh-Hant-TW", "zh-Hans-TW", "ja-TW", "en-TW"])
                }
            }
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
    let container = try! ModelContainer(for: AudioRecord.self, Settings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(AudioRecord.sampleData[0])
    return TranscriptView(errorWrapper: .constant(.emptyError))
        .modelContainer(container)
    //    TranscriptView(errorWrapper: .constant(.emptyError))
    //        .modelContainer(for: [AudioRecord.self, AppSettings.self], inMemory: true)
}
