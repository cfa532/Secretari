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
    @Query private var settings: [Settings]
    @Query(sort: \AudioRecord.recordDate, order: .reverse) var records: [AudioRecord]
    @Environment(\.scenePhase) var scenePhase

    @State private var isRecording = false
    @State private var curRecord: AudioRecord?    // create an empty record
    @Binding var errorWrapper: ErrorWrapper?
    
    @StateObject private var websocket = Websocket()
    @StateObject private var recorderTimer = RecorderTimer()
    @StateObject private var speechRecognizer = SpeechRecognizer()

    @State private var selectedLocale: RecognizerLocale?
    @State private var promptType = Settings.PromptType.memo
    @State private var selectedPrompt: String = AppConstants.defaultSettings.prompt[Settings.PromptType.memo]![AppConstants.defaultSettings.selectedLocale]!

    
    var body: some View {
        NavigationStack {
            if isRecording {
                ScrollView {
                    ScrollViewReader { proxy in
                        HStack {
                            Label("Recognizing", systemImage: "ear.badge.waveform")
                            Picker("Language:", selection: $selectedLocale) {
                                ForEach(RecognizerLocale.allCases, id:\.self) { option in
                                    Text(String(describing: option))
                                }
                            }
                            .onChange(of: selectedLocale) {
                                settings[0].selectedLocale = selectedLocale!
                                speechRecognizer.stopTranscribing()
                                Task {
                                    await self.speechRecognizer.setup(locale: settings[0].selectedLocale.rawValue)
                                    speechRecognizer.startTranscribing()
                                }
                            }
                        }
                        
                        let message = speechRecognizer.transcript
                        Text(message)
                            .id(message)
                            .onChange(of: message, {
                                proxy.scrollTo(message, anchor: .bottom)
                            })
                            .frame(alignment: .topLeading)
                    }
                }
                .padding()
                .animation(.easeInOut, value: 1)
                .onAppear(perform: {
                    selectedLocale = settings[0].selectedLocale
                })
            } else if websocket.isStreaming {
                ScrollView {
                    ScrollViewReader { proxy in
                        Label(NSLocalizedString("Streaming from AI...", comment: ""), systemImage: "brain.head.profile.fill")
                        let message = websocket.streamedText
                        Text(message)
                            .id(message)
                            .onChange(of: message, {
                                proxy.scrollTo(message, anchor: .bottom)
                            })
                    }
                }
                .padding()
                .animation(.easeInOut, value: 1)
            }
            else {
                List {
                    ForEach(records, id: \.recordDate) { item in
                        NavigationLink {
                            DetailView(record: item)
                        } label: {
                            let curDate: String = AudioRecord.dateFormatter.string(from: item.recordDate)
                            Text(curDate+": "+item.summary)
                                .font(.subheadline)
                                .lineLimit(4)
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
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing, content: {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.secondary)
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
            }
            
            RecorderButton(isRecording: $isRecording) {
                if self.isRecording {
                    print("Start timer. Audio db=\(self.settings[0].audioSilentDB)")
                    self.curRecord = AudioRecord()
                    recorderTimer.delegate = self
                    recorderTimer.startTimer()
                    {
                        // body of isSilent(), updated by frequency
                        print("audio level=", SpeechRecognizer.currentLevel)
                        self.curRecord?.transcript = speechRecognizer.transcript     // SwiftData of record updated periodically.
                        return SpeechRecognizer.currentLevel < Float(self.settings[0].audioSilentDB)! ? true : false
                    }
                    Task { 
                        await self.speechRecognizer.setup(locale: settings[0].selectedLocale.rawValue)
                        speechRecognizer.startTranscribing()
                    }
                } else {
                    
                    speechRecognizer.stopTranscribing()
                    recorderTimer.stopTimer()
                    
                }
            }
            .disabled(websocket.isStreaming)
            .frame(alignment: .bottom)
        }
        .alert(item: $websocket.alertItem) { alertItem in
            Alert(title: alertItem.title,
                  message: alertItem.message,
                  dismissButton: alertItem.dismissButton)
        }
    }
}

extension TranscriptView: TimerDelegate {
    
    @MainActor func timerStopped() {
        
        // body of action() closure
        self.isRecording = false
        guard speechRecognizer.transcript != "" else { print("No audio input"); return }
        Task {
            curRecord?.transcript = speechRecognizer.transcript + "。"
            modelContext.insert(curRecord!)
            speechRecognizer.transcript = ""
            websocket.sendToAI(curRecord!.transcript, prompt: settings[0].prompt[settings[0].promptType!]![settings[0].selectedLocale]!, wssURL: settings[0].wssURL) { summary in
                curRecord?.summary = summary
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
