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
    @State private var showPopup = false
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
                    Text(AudioRecord.dateLongFormat.string(from: record.recordDate))
                        .padding(3)
                    if (settings[0].promptType == .memo) {
                        DetailBulletinView(record: $record)
                    } else {
                        Text(record.summary[record.locale]!)
//                        TextField(record.summary[record.locale]!, text: $record.summary[record.locale], axis: .vertical)
//                            .lineLimit(.max)
//                            .textSelection(.enabled)
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
                        print(settings[0].prompt[settings[0].promptType]![settings[0].selectedLocale]!)
                        Task { @MainActor in
                            let setting = settings[0]
                            websocket.sendToAI(record.transcript, prompt: setting.prompt[setting.promptType]![setting.selectedLocale]!, wssURL: setting.wssURL) { summary in
                                if setting.promptType == .memo {
                                    record.memo = []
                                } else {
                                    record.summary[record.locale] = summary
                                }
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
