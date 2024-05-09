//
//  DetailView.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/29.
//

import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @Environment(\.dismiss) var dismiss
    
    @State var record: AudioRecord
    @Binding var isRecording: Bool
    @State private var selectedLocale: RecognizerLocale = AppConstants.defaultSettings.selectedLocale
    
    @State private var showShareSheet = false
    @State private var isShowingDialog = false  // for Redo confirm dialog
    
    @StateObject private var websocket = Websocket()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var recorderTimer = RecorderTimer()
//    @State private var curRecord: AudioRecord?    // create an empty new audio record
    
    var body: some View {
        NavigationStack {
            if self.isRecording {
                ScrollView {
                    ScrollViewReader { proxy in
                        HStack {
                            Label("Recognizing", systemImage: "ear.badge.waveform")
                            Picker("Language:", selection: $selectedLocale) {
                                ForEach(RecognizerLocale.allCases, id:\.self) { option in
                                    Text(String(describing: option))
                                }
                            }
                            .onAppear(perform: {
                                selectedLocale = settings[0].selectedLocale
                            })
                            .onChange(of: selectedLocale) {
                                settings[0].selectedLocale = selectedLocale
                                speechRecognizer.stopTranscribing()
                                Task {
                                    await self.speechRecognizer.setup(locale: settings[0].selectedLocale.rawValue)
                                    speechRecognizer.startTranscribing()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
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
                .onAppear(perform: {
                    print("Start timer. Audio db=\(self.settings[0].audioSilentDB)")
//                    self.curRecord = AudioRecord()
                    recorderTimer.delegate = self
                    recorderTimer.startTimer()
                    {
                        // body of isSilent(), updated by frequency per 10s
                        print("audio level=", SpeechRecognizer.currentLevel)
                        self.record.transcript = speechRecognizer.transcript     // SwiftData of record updated periodically.
                        return SpeechRecognizer.currentLevel < Float(self.settings[0].audioSilentDB)! ? true : false
                    }
                    Task {
                        await self.speechRecognizer.setup(locale: settings[0].selectedLocale.rawValue)
                        speechRecognizer.startTranscribing()
                    }
                })
//                Spacer()
                RecorderButton(isRecording: $isRecording) {
                    if self.isRecording {
//                        print("Start timer. Audio db=\(self.settings[0].audioSilentDB)")
//                        self.record = AudioRecord()
//                        recorderTimer.delegate = self
//                        recorderTimer.startTimer()
//                        {
//                            // body of isSilent(), updated by frequency per 10s
//                            print("audio level=", SpeechRecognizer.currentLevel)
//                            self.curRecord?.transcript = speechRecognizer.transcript     // SwiftData of record updated periodically.
//                            return SpeechRecognizer.currentLevel < Float(self.settings[0].audioSilentDB)! ? true : false
//                        }
//                        Task {
//                            await self.speechRecognizer.setup(locale: settings[0].selectedLocale.rawValue)
//                            speechRecognizer.startTranscribing()
//                        }
                    } else {
                        speechRecognizer.stopTranscribing()
                        recorderTimer.stopTimer()
                    }
                }
                .disabled(websocket.isStreaming)
                .frame(alignment: .bottom)
                
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
                Spacer()
            } else {
                ScrollView {
                    HStack {
                        Text(AudioRecord.dateLongFormat.string(from: record.recordDate))
                        Spacer()
                        LocalePicker(promptType: settings[0].promptType, record: $record)
                    }
                    .padding(3)
                    
                    if (settings[0].promptType == .memo) {
                        if !record.memo.isEmpty {
                            DetailBulletinView(record: $record)
                        } else {
                            Text(record.summary[record.locale] ?? "No summary. Try to regenerate summary")
                        }
                    } else {
                        if !record.summary.isEmpty {
                            TextField(record.summary[record.locale] ?? "No summary. Try to regenerate summary",
                                      text: Binding(
                                        get: {record.summary[record.locale] ?? "No summary. Try to regenerate summary"},
                                        set: {newValue in
                                            record.summary[record.locale] = newValue
                                        }), axis: .vertical)
                            .lineLimit(.max)
                            .textSelection(.enabled)
                        } else {
                            DetailBulletinView(record: $record)
                        }
                    }
                }
                .padding()
            }
        }

        .navigationBarBackButtonHidden(true)
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    // Dismiss the view
                    dismiss()
                }, label: {
                    Image(systemName: "decrease.indent")
                        .resizable() // Might not be necessary for system images
                })
                .disabled(isRecording)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu(content: {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    NavigationLink(destination: DetailTranscriptView(record: record)) {
                        Label("Transcript", systemImage: "text.word.spacing")
                    }
                    
                    NavigationLink(destination: DetailTranslationView(record: $record, websocket: websocket)) {
                        Label("Translation", systemImage: "textformat.abc.dottedunderline")
                    }
                    
                    Button {
                        // regenerate summary of recording
                        print(settings[0].prompt[settings[0].promptType]![settings[0].selectedLocale]!)
                        Task { @MainActor in
                            let setting = settings[0]
                            websocket.sendToAI(record.transcript, prompt: setting.prompt[setting.promptType]![setting.selectedLocale]!, wssURL: setting.wssURL) { summary in
                                
                                record.locale = selectedLocale      // update current locale of the record
                                record.resultFromAI(promptType: setting.promptType, summary: summary)
                            }
                        }
                    } label: {
                        Label("Redo Summary", systemImage: "pencil.line")
                    }
                    
                }, label: {
                    Image(systemName: "ellipsis")
                })
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(activityItems: [textToShare()])
                }
                .disabled(isRecording)
            }
        })
        .alert(item: $websocket.alertItem) { alertItem in
            Alert(title: alertItem.title,
                  message: alertItem.message,
                  dismissButton: alertItem.dismissButton)
        }
    }
    
    struct ShareSheet: UIViewControllerRepresentable {
        let activityItems: [Any]
        func makeUIViewController(context: Context) -> UIActivityViewController {
            return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        }
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
    
    private func textToShare()->String {
        var textToShare = AudioRecord.dateLongFormat.string(from: record.recordDate) + ":\n"
        if settings[0].promptType == .memo {
            if !record.memo.isEmpty {
                for m in record.memo {
                    if let t = m.title[record.locale] {
                        textToShare.append((m.isChecked ? "☑ " : "☐ ") + t + "\n")
                    }
                }
            }
        } else {
            if !record.summary.isEmpty {
                if let t = record.summary[record.locale] {
                    textToShare += t
                }
            }
        }
        return textToShare
    }
}

extension DetailView: TimerDelegate {
    @MainActor func timerStopped() {
        // body of action() closure
        self.isRecording = false
        guard speechRecognizer.transcript != "" else { print("No audio input"); dismiss(); return }
        Task {
            record.transcript = speechRecognizer.transcript + "。"
            modelContext.insert(record)
            speechRecognizer.transcript = ""
            let setting = settings[0]
            websocket.sendToAI(record.transcript, prompt: setting.prompt[setting.promptType]![selectedLocale]!, wssURL: setting.wssURL) { summary in
                record.locale = selectedLocale
                record.resultFromAI(promptType: settings[0].promptType, summary: summary)
            }
        }
    }
}

#Preview {
    DetailView(record: AudioRecord.sampleData[0], isRecording: .constant(false))
    //    let container = try! ModelContainer(for: AudioRecord.self, Settings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    //    return DetailView(record: AudioRecord.sampleData[0])
    //        .modelContainer(container)
}
