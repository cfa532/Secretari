//
//  DetailTranslationView.swift
//  Secretari
//
//  Created by 超方 on 2024/4/30.
//

import SwiftUI
import SwiftData

struct DetailTranslationView: View {
    @Binding var record: AudioRecord
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @StateObject private var websocket = Websocket()
    @State private var showShareSheet = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if websocket.isStreaming {
                    ScrollViewReader { proxy in
                        let message = self.websocket.streamedText
                        Label(NSLocalizedString("Streaming from AI...", comment: ""), systemImage: "brain.head.profile.fill")
                        Text(message)
                            .id(message)
                            .onChange(of: message, {
                                proxy.scrollTo(message, anchor: .bottom)
                            })
                    }
                    //                } else if !record.translation.isEmpty {
                    //                    Text(record.translation[record.translation.keys.first!]!)
                } else {
                    ContentUnavailableView(label: {
                        Label("No records", systemImage: "list.bullet.rectangle.portrait")
                    }, description: {
                        Text("Select one of the following languages to translate the Summary")
                        Button("English") {
                            if settings[0].promptType == .memo {
                                do {
                                    var arr = []
                                    for m in record.memo {
                                        arr.append(["id":m.id, "title": String(describing: m.title[record.locale]!), "isChecked":m.isChecked])
                                    }
                                    let jsonData = try JSONSerialization.data(withJSONObject: arr, options: [])
                                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                                        
                                        let prompt = "The following text is a valid JSON string. Translate the title of each JSON object into English. Only return a pure JSON string in the same format. "
                                        websocket.sendToAI(jsonString, prompt: prompt, wssURL: settings[0].wssURL) { translation in
                                            do {
                                                // extract valie JSON string from AI reply
                                                let regex = try NSRegularExpression(pattern: "\\[(.*?)\\]", options: [])
                                                let nsString = translation as NSString
                                                let results = regex.matches(in: translation, options: [], range: NSRange(location: 0, length: nsString.length))
                                                let r = results.map{ nsString.substring(with: $0.range(at: 1)) }
                                                
                                                record.locale = .English
                                                record.upateFromAI(promptType: settings[0].promptType, summary: "["+r[0]+"]")
                                                try? modelContext.save()
                                                //    self.presentationMode.wrappedValue.dismiss()
                                            } catch let error {
                                                print("Invalid regex: \(error.localizedDescription)")
                                            }
                                        }
                                    } else {
                                        print("Failed to convert data to string.")
                                    }
                                } catch {
                                    print("Error converting JSON object to Data:", error)
                                }
                            } else {
                                var prompt = "translate the following text into English. "
                                websocket.sendToAI(record.summary[record.locale]!, prompt: prompt, wssURL: settings[0].wssURL) { translation in
                                    record.summary[.English] = translation
                                    try? modelContext.save()
                                }
                            }
                        }
                        Button("Indonesia") {
                            let prompt = "terjemahkan teks berikut ke dalam bahasa Indonesia. "
                            websocket.sendToAI(record.summary[record.locale]!, prompt: prompt, wssURL: settings[0].wssURL) { translation in
                                record.summary = [.Indonesia: translation]
                                try? modelContext.save()
                            }
                        }
                    })
                }
            }
            .padding()
        }
        .navigationTitle("Translation")
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Menu(content: {
                    Button {
                        print("show share meun")
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }, label: {
                    Image(systemName: "ellipsis")
                        .resizable()
                })
                .sheet(isPresented: $showShareSheet, content: {
                    if !record.summary.isEmpty  {
                        let textToShare = AudioRecord.dateLongFormat.string(from: record.recordDate) + ": "
                        ShareSheet(activityItems: [textToShare])
                    }
                })
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
    DetailTranslationView(record: .constant(AudioRecord.sampleData[0]))
}
