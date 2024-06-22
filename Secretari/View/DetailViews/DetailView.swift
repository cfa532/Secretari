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
    @EnvironmentObject private var speechRecognizer: SpeechRecognizer
    
    @Binding var isRecording: Bool
    @State var record: AudioRecord
    
    @State private var settings = SettingsManager.shared.getSettings()
    @State private var showShareSheet = false
    @State private var showRedoAlert = false  // for Redo confirm dialog
    
    @StateObject private var websocket = Websocket.shared
    @StateObject private var recorderTimer = RecorderTimer()
    
    private let suffixLength = 1000
    
    var body: some View {
        NavigationStack {
            if self.isRecording {
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack {
                            HStack {
                                Label {
                                    DotAnimationView(title: "recognizing")
                                } icon: {
                                    Image(systemName: "hearingdevice.ear")
                                }
                                .foregroundStyle(Color.accentColor)
                                .padding(.leading, 20)
                                .frame(maxWidth: .infinity, alignment: .leading) // Aligns the content to the rightmost side
                                
                                Picker("Language:", selection: $settings.selectedLocale) {
                                    ForEach(RecognizerLocale.allCases, id: \.self) { option in
                                        Text(String(describing: option))
                                    }
                                }
                                .onChange(of: settings.selectedLocale) {
                                    SettingsManager.shared.updateSettings(settings)
                                    speechRecognizer.stopTranscribing()
                                    Task {
                                        await self.speechRecognizer.setup(locale: settings.selectedLocale.rawValue)
                                        await self.speechRecognizer.startTranscribing()
                                    }
                                }
                            }
                            .padding(.bottom, 10)
                            
                            LazyVStack {
                                ForEach(speechRecognizer.transcript.suffix(suffixLength).split(separator: "\n"), id: \.self) { message in
                                    Text(message)
                                        .id(message)
                                }
                            }
                            .onChange(of: speechRecognizer.transcript.suffix(suffixLength)) { oldValue, newValue in
                                proxy.scrollTo(newValue.split(separator: "\n").last, anchor: .bottom)
                            }
                        }
                    }
                }
                .padding()
                .onAppear(perform: {
                    print("Start timer. Audio db=\(String(describing: self.settings.audioSilentDB))")
                    
                    recorderTimer.delegate = self   // register with recordTimer. It calls delegate when timer stops.
                    recorderTimer.startTimer() {
                        // body of isSilent(), updated by frequency per 10s
                        print("audio level=", SpeechRecognizer.currentLevel)
                        // SwiftData of record updated periodically.
                        self.record.transcript = speechRecognizer.transcript
                        return SpeechRecognizer.currentLevel < Float(self.settings.audioSilentDB)! ? true : false
                    }
                })
                RecorderButton(isRecording: $isRecording) {
                    if !self.isRecording {
                        speechRecognizer.stopTranscribing()
                        recorderTimer.stopTimer()
                    }
                }
                .disabled(websocket.isStreaming)
                .frame(alignment: .bottom)
                
            } else if websocket.isStreaming {
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(alignment: .leading) {
                            Label {
                                DotAnimationView(title: "Streaming from AI")
                            } icon: {
                                Image(systemName: "brain.head.profile.fill")
                            }
                            .foregroundStyle(Color.accentColor)
                            .padding(.leading, 50)
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, alignment: .leading) // Aligns the content to the rightmost side
                            
                            let message = websocket.streamedText.suffix(suffixLength)
                            Text(message)
                                .id(message)
                                .onChange(of: message, {
                                    proxy.scrollTo(message, anchor: .bottom)
                                })
                        }
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
                    
                    if (settings.promptType == .checklist) {
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
//                        .resizable()
                        .frame(width: 23, height: 23)
                        .padding(7)
                        .contentShape(Rectangle())      // increase tappable area
                })
                .alert("Alert", isPresented: $showRedoAlert, actions: {
                    Button("No", role: .cancel) { }
                    Button("Yes") {
                        // get updated settings
                        self.settings = SettingsManager.shared.getSettings()
                        // clear old summary,
                        if settings.promptType == .checklist {
                            record.memo.removeAll()
                        } else {
                            record.summary.removeAll()
                        }
                        websocket.sendToAI(record.transcript, prompt: "") { result in
                            record.locale = settings.selectedLocale       // update current locale of the record
                            record.resultFromAI(taskType: .summarize, summary: result)
                        }
                    }
                }, message: {
                    Text(LocalizedStringKey("Regenerate summary from the transcript. Existing content will be overwritten."))
                        .font(.title)
                })
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(activityItems: [textToShare()])
                }
                .disabled(isRecording)
            }
        })
        .alert("Websocket Error", isPresented: $websocket.showAlert, presenting: websocket.alertItem) { _ in
        } message: { alertItem in
            alertItem.message
        }
        .onAppear(perform: {
            settings = SettingsManager.shared.getSettings()     // update settings which may changed somewhere else.
        })
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
        if settings.promptType == .checklist {
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
    func timerStopped() {
        // body of action() closure
        self.isRecording = false
        guard speechRecognizer.transcript != "" else {
            print("No audio input");
            dismiss();      // go back to parent view
            return }
        Task { @MainActor in
            record.transcript = speechRecognizer.transcript
            modelContext.insert(record)
            speechRecognizer.transcript = ""
            self.settings = SettingsManager.shared.getSettings()
            
            // If no prompt given, use the system setting's prompt.
            websocket.sendToAI(record.transcript, prompt: "") { result in
                record.locale = settings.selectedLocale
                record.resultFromAI(taskType: .summarize, summary: result)
            }
        }
    }
    
    func segmentText(_ text: String, segmentLength: Int, overlapLength: Int = 50) -> [String] {
        var segments: [String] = []
        var startIndex = text.startIndex
        
        while startIndex < text.endIndex {
            let endIndex = text.index(startIndex, offsetBy: segmentLength, limitedBy: text.endIndex) ?? text.endIndex
            let segment = String(text[startIndex..<endIndex])
            segments.append(segment)
            
            // Move the start index forward by segmentLength - overlapLength
            startIndex = text.index(startIndex, offsetBy: segmentLength - overlapLength, limitedBy: text.endIndex) ?? text.endIndex
        }
        return segments
    }
}

#Preview {
    DetailView(isRecording: .constant(true), record: AudioRecord.sampleData[0])
        .environmentObject(SpeechRecognizer())
}

