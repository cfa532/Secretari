//
//  DetailView.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/29.
//

import SwiftUI
import SwiftData

// This view displays the details of an audio recording, including transcription, summary,
// and options to share, translate, and regenerate the summary.
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
    
    private let suffixLength = 1000     // Constant to limit the length of displayed text.
    
    var body: some View {
        NavigationStack {
            if self.isRecording {
                // Display the transcription view while recording.
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack {
                            HStack {
                                Label {
                                    // Display a dot animation to indicate recognition is in progress.
                                    DotAnimationView(title: "recognizing_status")
                                } icon: {
                                    HStack {
                                        // Picker to select the language for speech recognition.
                                        Picker("Language:", selection: $settings.selectedLocale) {
                                            ForEach(RecognizerLocale.availables, id: \.self) { option in
                                                Text(String(describing: option))
                                            }
                                        }
                                        .onChange(of: settings.selectedLocale) {
                                            // Update settings and restart speech recognition when the locale changes.
                                            SettingsManager.shared.updateSettings(settings)
                                            speechRecognizer.stopTranscribing()
                                            Task {
                                                await self.speechRecognizer.setup(locale: settings.selectedLocale.rawValue)
                                                await self.speechRecognizer.startTranscribing()
                                            }
                                        }
                                        Image(systemName: "hearingdevice.ear")
                                    }
                                }
                                .foregroundStyle(Color.accentColor)
                                .padding(.leading, 20)
                                .frame(maxWidth: .infinity, alignment: .leading) // Aligns the content to the rightmost side
                                
                            }
                            .padding(.bottom, 10)
                            // Display the transcribed text in realtime, line by line.
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
                    
                    // Register with the recorder timer to receive timer stop events.
                    recorderTimer.delegate = self
                    recorderTimer.startTimer() {
                        // body of isSilent(), updated at frequency of 10s
                        print("audio level=", SpeechRecognizer.currentLevel)
                        // SwiftData of record updated periodically.
                        self.record.transcript = speechRecognizer.transcript
                        return SpeechRecognizer.currentLevel < Float(self.settings.audioSilentDB)! ? true : false
                    }
                })
                // Display the record button.
                RecorderButton(isRecording: $isRecording) {
                    if !self.isRecording {
                        speechRecognizer.stopTranscribing()
                        recorderTimer.stopTimer()
                    }
                }
                .disabled(websocket.isStreaming)
                .frame(alignment: .bottom)
                
            } else if websocket.isStreaming {
                // Display the streaming view while the AI is processing.
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
                            
                            // Display the streamed text.
                            let message = websocket.streamedText.suffix(suffixLength)
                            Text(message)
                                .id(message)
                                .onChange(of: message, {
                                    // Scroll to the bottom when new text is streamed.
                                    proxy.scrollTo(message, anchor: .bottom)
                                })
                        }
                    }
                }
                .padding()
                Spacer()
            } else {
                // Display the summary view when work is done.
                ScrollView {
                    HStack {
                        Text(AudioRecord.dateLongFormat.string(from: record.recordDate))
                        Spacer()
                        LocalePicker(promptType: settings.promptType, record: $record)
                    }
                    .padding(3)
                    // Conditional rendering based on the prompt type.
                    if (settings.promptType == .checklist) {
                        if !record.memo.isEmpty {
                            DetailBulletinView(record: $record)
                        } else {
                            Text(record.summary[record.locale] ?? "No summary. Try to regenerate summary")
                        }
                    } else {
                        // Display the summary text field.
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
        .navigationTitle(LocalizedStringKey("Summary"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            // Toolbar item for the back button.
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    // Dismiss the view
                    dismiss()
                }, label: {
                    Image(systemName: "decrease.indent")
                        .frame(width: 23, height: 23)
                        .padding(7)
                        .contentShape(Rectangle())      // increase tappable area
                })
                .disabled(isRecording)
            }
            // Toolbar item for the options menu.
            ToolbarItem(placement: .topBarTrailing) {
                Menu(content: {
                    // Button to share the summary.
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    // Navigation link to the transcript view.
                    NavigationLink(destination: DetailTranscriptView(record: record)) {
                        Label("Transcript", systemImage: "text.word.spacing")
                    }
                    // Navigation link to the translation view.
                    NavigationLink(destination:
                                    DetailTranslationView(record: $record)
                    ) {
                        Label("Translation", systemImage: "textformat.abc.dottedunderline")
                    }
                    // Button to regenerate the summary.
                    Button {
                        // regenerate summary of recording
                        self.showRedoAlert = true
                    } label: {
                        Label("Summarize", systemImage: "pencil.line")
                    }
                }, label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 23, height: 23)
                        .padding(7)
                        .contentShape(Rectangle())      // increase tappable area
                })
                .alert(LocalizedStringKey("Alert"), isPresented: $showRedoAlert, actions: {
                    Button(LocalizedStringKey("No"), role: .cancel) { }
                    Button(LocalizedStringKey("Yes")) {
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
                    // Display the share sheet.
                    ShareSheet(activityItems: [textToShare()])
                }
                .disabled(isRecording)
            }
        })
        .alert("Websocket Error", isPresented: $websocket.showAlert, presenting: websocket.alertItem) { _ in
        } message: { alertItem in
            // Display websocket error messages.
            alertItem.message
        }
        .onAppear(perform: {
            // Update settings when the view appears, which may be changed somewhere else.
            settings = SettingsManager.shared.getSettings()
            
            // Check if record has appropriate content for current prompt type and auto-generate if needed
            checkAndGenerateContentIfNeeded()
        })
    }
    
    struct ShareSheet: UIViewControllerRepresentable {
        let activityItems: [Any]
        func makeUIViewController(context: Context) -> UIActivityViewController {
            return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        }
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
    
    /// Checks if the record has appropriate content for the current prompt type and auto-generates if needed
    private func checkAndGenerateContentIfNeeded() {
        // Only proceed if not recording and not already streaming
        guard !isRecording && !websocket.isStreaming else { return }
        
        // Check if record has appropriate content for current prompt type
        let hasAppropriateContent: Bool
        if settings.promptType == .checklist {
            // For checklist type, check if memo is not empty
            hasAppropriateContent = !record.memo.isEmpty
        } else {
            // For summary type, check if summary is not empty for current locale
            hasAppropriateContent = !record.summary.isEmpty && !(record.summary[record.locale]?.isEmpty ?? true)
        }
        
        // If no appropriate content exists, auto-generate it
        if !hasAppropriateContent && !record.transcript.isEmpty {
            // Check if transcript has minimum length before sending to AI
            let trimmedTranscript = record.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedTranscript.count >= 20 else {
                print("Transcript too short, skipping AI generation")
                return
            }
            
            // Clear existing content of the wrong type
            if settings.promptType == .checklist {
                record.summary.removeAll()
            } else {
                record.memo.removeAll()
            }
            
            // Generate content using sendToAI (which now has its own validation)
            websocket.sendToAI(record.transcript, prompt: "") { result in
                record.locale = settings.selectedLocale
                record.resultFromAI(taskType: .summarize, summary: result)
            }
        }
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

// Extension to conform to the TimerDelegate protocol.
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
    // Function to segment text into smaller chunks.
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

