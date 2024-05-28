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
    @Environment(\.dismiss) var dismiss
    
    @Binding var isRecording: Bool
    @State var record: AudioRecord
    @Binding var settings: Settings

    @State private var showShareSheet = false
    @State private var showRedoAlert = false  // for Redo confirm dialog

    @StateObject private var websocket = Websocket.shared
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var recorderTimer = RecorderTimer()
        
    var body: some View {
        NavigationStack {
            if self.isRecording {
                ScrollView {
                    ScrollViewReader { proxy in
                        HStack {
                            Label("Recognizing", systemImage: "ear.badge.waveform")
                            Picker("Language:", selection: $settings.selectedLocale) {
                                ForEach(RecognizerLocale.allCases, id:\.self) { option in
                                    Text(String(describing: option))
                                }
                            }
                            .onChange(of: settings.selectedLocale) {
                                SettingsManager.shared.updateSettings(settings)
                                speechRecognizer.stopTranscribing()
                                Task {
                                    await self.speechRecognizer.setup(locale: settings.selectedLocale.rawValue)
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
                    print("Start timer. Audio db=\(String(describing: self.settings.audioSilentDB))")
                    recorderTimer.delegate = self
                    recorderTimer.startTimer()
                    {
                        // body of isSilent(), updated by frequency per 10s
                        print("audio level=", SpeechRecognizer.currentLevel)
                        self.record.transcript = speechRecognizer.transcript     // SwiftData of record updated periodically.
                        return SpeechRecognizer.currentLevel < Float(self.settings.audioSilentDB)! ? true : false
                    }
                    Task {
                        await self.speechRecognizer.setup(locale: settings.selectedLocale.rawValue)
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
                        LocalePicker(promptType: settings.promptType, record: $record)
                    }
                    .padding(3)
                    
                    if (settings.promptType == .memo) {
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
                    //                    dismiss()
                }, label: {
                    Image(systemName: "decrease.indent")
                        .resizable() // Might not be necessary for system images
                        .tappablePadding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)) {
                            dismiss()
                        }
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
                    
                    NavigationLink(destination:
                            DetailTranslationView(record: $record)
                    ) {
                        Label("Translation", systemImage: "textformat.abc.dottedunderline")
                    }
                    
                    Button {
                        // regenerate summary of recording
                        self.showRedoAlert = true
                    } label: {
                        Label("Summarize", systemImage: "pencil.line")
                    }
                }, label: {
                    Image(systemName: "ellipsis")
                })
                .alert(isPresented: $showRedoAlert, content: {
                    Alert(title: Text("Alert"), message: Text("Regenerate summary from transcript. Existing content will be overwritten."), primaryButton: .cancel(), secondaryButton: .destructive(Text("Yes"), action: {
                        Task { @MainActor in
                            websocket.sendToAI(record.transcript) { result in
                                
                                record.locale = settings.selectedLocale      // update current locale of the record
                                record.resultFromAI(promptType: settings.promptType, summary: result)
                            }
                        }
                    }))
                })
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(activityItems: [textToShare()])
                }
                .disabled(isRecording)
            }
        })
//        .alert(item: $websocket.alertItem) { alertItem in
//            Alert(title: alertItem.title,
//                  message: alertItem.message,
//                  dismissButton: alertItem.dismissButton)
//        }
        .alert(("Websocket Error"), isPresented: $websocket.showAlert, presenting: websocket.alertItem) { alertItem in
            alertItem.message
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
        if settings.promptType == .memo {
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
            websocket.sendToAI(record.transcript) { result in
                record.locale = settings.selectedLocale
                record.resultFromAI(promptType: settings.promptType, summary: result)
            }
        }
    }
}

#Preview {
    DetailView(isRecording: .constant(true), record: AudioRecord.sampleData[0], settings: .constant(AppConstants.defaultSettings))
    //    let container = try! ModelContainer(for: AudioRecord.self, Settings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    //    return DetailView(record: AudioRecord.sampleData[0])
    //        .modelContainer(container)
}
 
