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
    @Query(sort: \AudioRecord.recordDate, order: .reverse) private var records: [AudioRecord]
    @Query private var settings: [AppSettings]
    
    @State private var isRecording = false
    @Binding var errorWrapper: ErrorWrapper?
    @StateObject private var websocket = Websocket()
    @StateObject private var recorderTimer = RecorderTimer()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        NavigationStack {
            if isRecording {
                ScrollView {
                    ScrollViewReader { proxy in
                        let t = "Recognizing....in " + String(describing: RecognizerLocals(rawValue: settings[0].speechLocale)!) + "\n"
                        let message = t + speechRecognizer.transcript
                        Text(message)
                            .id(message)
                            .onChange(of: message, {
                                proxy.scrollTo(message, anchor: .bottom)
                            })
                            .frame(alignment: .topLeading)
                    }
                }
                .padding()
            } else if websocket.isStreaming {
                ScrollView {
                    ScrollViewReader { proxy in
                        let message = "Streaming from AI...\n" + websocket.streamedText
                        Text(message)
                            .id(message)
                            .onChange(of: message, {
                                proxy.scrollTo(message, anchor: .bottom)
                            })
                    }
                }
                .padding()
            }
            else {
                List {
                    ForEach(records) { item in
                        NavigationLink {
                            DetailView(record: item)
                        } label: {
                            let curDate: String = AudioRecord.dateFormatter.string(from: item.recordDate)
                            Text(curDate+": "+item.summary)
                                .font(.subheadline)
                                .lineLimit(4)
                        }
                    }
                }
                .overlay(content: {
                    if records.isEmpty {
                        ContentUnavailableView(label: {
                            Label("No records", systemImage: "list.bullet.rectangle.portrait")
                        }, description: {
                            Text("Push the START button to record your own speech. A summary will be generated automatically after STOP button is pushed.")
                        })
                    }
                })
                .navigationTitle("Daily Records")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing, content: {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.primary)
                        }
                    })
                }
                .task {
                    let lc = NSLocale.current.language.languageCode?.identifier
                    print(lc!)
                    if settings.isEmpty {
                        // first run of the App, settings not stored by SwiftData yet.
                        
                        let setting = AppSettings.defaultSettings
                        switch lc {
                        case "en":
                            setting.speechLocale = RecognizerLocals.English.rawValue
                        case "jp":
                            setting.speechLocale = RecognizerLocals.Japanese.rawValue
                        default:
                            setting.speechLocale = RecognizerLocals.Chinese.rawValue
                        }
                        modelContext.insert(setting)
                        try? modelContext.save()
                    }
                }
            }
            
            RecorderButton(isRecording: $isRecording) {
                if isRecording {
                    print("Start timer. Audio db=\(self.settings[0].audioSilentDB)")
                    recorderTimer.delegate = self
                    recorderTimer.startTimer() {
                        
                        // body of isSilent()
                        print("audio level=", SpeechRecognizer.currentLevel)
                        if SpeechRecognizer.currentLevel < Float(self.settings[0].audioSilentDB)! {
                            return true
                        } else {
                            return false
                        }
                    }
                    Task { @MainActor in
                        await self.speechRecognizer.setup(locale: settings[0].speechLocale)
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
    }
}

extension TranscriptView: TimerDelegate {
    
    @MainActor func timerStopped() {
        
        // body of action() closure
        isRecording = false
        guard speechRecognizer.transcript != "" else { print("No audio input"); return }
        
        let curDate: String = AudioRecord.dateFormatter.string(from: Date())
        Task {
            if let index = records.firstIndex(where: {curDate == AudioRecord.dateFormatter.string(from: $0.recordDate)}) {
                // check if today's record exists
                records[index].transcript +=  speechRecognizer.transcript+"。"
                websocket.sendToAI(speechRecognizer.transcript, settings: self.settings[0]) { summary in
                    records[index].summary = summary
                }
            } else {
                let curRecord = AudioRecord(transcript: speechRecognizer.transcript+"。", summary: curDate)
                // If anything goes wrong wit AI, still have the transcript.
                modelContext.insert(curRecord)
                websocket.sendToAI(speechRecognizer.transcript, settings: self.settings[0]) { summary in
                    curRecord.summary = summary
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: AudioRecord.self, AppSettings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    container.mainContext.insert(AudioRecord.sampleData[0])
    return TranscriptView(errorWrapper: .constant(.emptyError))
        .modelContainer(container)
//    TranscriptView(errorWrapper: .constant(.emptyError))
//        .modelContainer(for: [AudioRecord.self, AppSettings.self], inMemory: true)
}
