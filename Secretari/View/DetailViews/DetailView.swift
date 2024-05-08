//
//  DetailView.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/29.
//

import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var record: AudioRecord
    
    @State private var showShareSheet = false
    @State private var isShowingDialog = false  // for Redo confirm dialog
    
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @StateObject private var websocket = Websocket()
    
    private let selectedLocale: RecognizerLocale = AppConstants.defaultSettings.selectedLocale
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if self.websocket.isStreaming {
                    ScrollViewReader { proxy in
                        let message = self.websocket.streamedText
                        Label(NSLocalizedString("Streaming from AI...", comment: ""), systemImage: "brain.head.profile.fill")
                        Text(message)
                            .id(message)
                            .onChange(of: message, {
                                proxy.scrollTo(message, anchor: .bottom)
                            })
                    }
                    .animation(.easeInOut, value: 1)
                } else {
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
                            Text(record.summary[record.locale] ?? "No summary")
                        }
                    } else {
                        if !record.summary.isEmpty {
                            TextField(record.summary[record.locale] ?? "No summary",
                                      text: Binding(
                                        get: {record.summary[record.locale] ?? "No summary"},
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
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    // Dismiss the view
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "decrease.indent")
                        .resizable() // Might not be necessary for system images
                })
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
                    
                    NavigationLink(destination: DetailTranslationView(record: $record)) {
                        Label("Translation", systemImage: "textformat.abc.dottedunderline")
                    }
                    
                    Button {
                        // regenerate summary of recording
                        print(settings[0].prompt[settings[0].promptType]![settings[0].selectedLocale]!)
                        Task { @MainActor in
                            let setting = settings[0]
                            websocket.sendToAI(record.transcript, prompt: setting.prompt[setting.promptType]![setting.selectedLocale]!, wssURL: setting.wssURL) { summary in
                                
                                record.locale = selectedLocale      // update current locale of the record
                                record.upateFromAI(promptType: setting.promptType, summary: summary)
                            }
                        }
                    } label: {
                        Label("Redo Summary", systemImage: "pencil.line")
                    }
                    
                }, label: {
                    Image(systemName: "ellipsis")
                })
                .sheet(isPresented: $showShareSheet) {
                    let textToShare = AudioRecord.dateLongFormat.string(from: record.recordDate) + ": " + record.summary[record.locale]!
                    ShareSheet(activityItems: [textToShare])
                }
            }
        })
    }
    
    struct ShareSheet: UIViewControllerRepresentable {
        let activityItems: [Any]
        func makeUIViewController(context: Context) -> UIActivityViewController {
            return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        }
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
}

#Preview {
    DetailView(record: (AudioRecord.sampleData[0]))
    //    let container = try! ModelContainer(for: AudioRecord.self, Settings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    //    return DetailView(record: AudioRecord.sampleData[0])
    //        .modelContainer(container)
}
