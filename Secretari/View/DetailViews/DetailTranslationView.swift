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
    @Environment(\.dismiss) var dismiss
    
    @State private var alertItem: AlertItem?
    
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
                } else {
                    ContentUnavailableView(label: {
                        Label("", systemImage: "list.bullet.rectangle.portrait")
                    }, description: {
                        Text("Select one of the following languages to translate the Summary. If summary exists, it will be overwritten.")
                        Button("English") {
                            if settings[0].promptType == .memo {
                                translateMemo(locale: .English, record: record, prompt: "The following text is a valid JSON string. Translate the title of each JSON object into English. Only return a pure JSON string in the same format. ")
                            } else {
                                translateSummary(locale: .English, record: record, prompt: "translate the following text into English. ")
                            }
                        }
                        Button("Indonesia") {
                            if settings[0].promptType == .memo {
                                translateMemo(locale: .Indonesia, record: record, prompt: "Teks berikut adalah string JSON yang valid. Terjemahkan judul setiap objek JSON ke dalam bahasa Indonesia. Hanya kembalikan string JSON murni dalam format yang sama. ")
                            } else {
                                translateSummary(locale: .Indonesia, record: record, prompt: "terjemahkan teks berikut ke dalam bahasa Indonesia. ")
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
        .alert(item: self.$alertItem) { alertItem in
            Alert(title: alertItem.title,
                  message: alertItem.message,
                  dismissButton: alertItem.dismissButton)
        }
    }
    
    private func translateSummary(locale: RecognizerLocale, record: AudioRecord, prompt: String) {
        if let summary = record.summary[record.locale] {
            websocket.sendToAI(summary, prompt: prompt, wssURL: settings[0].wssURL) { translation in
                record.locale = locale
                record.summary[locale] = translation
                try? modelContext.save()
                Task {
                    dismiss()
                }
            }
        } else {
//            print("No summary to translate.")
            self.alertItem = AlertContext.emptySummary
        }
    }
    
    private func translateMemo(locale: RecognizerLocale, record: AudioRecord, prompt: String) {
        do {
            var arr:[Any] = [Any]()
            if !record.memo.isEmpty {
                for m in record.memo {
                    arr.append(["id":m.id, "title": String(describing: m.title[record.locale]!), "isChecked":m.isChecked])
                }
            } else {
                // no memo for the record, create one from its summary
//                arr.append(["id":1, "title": record.summary[record.locale]!, "isChecked": false])
                print("No memo to print")
                self.alertItem = AlertContext.emptyMemo
                
            }
            let jsonData = try JSONSerialization.data(withJSONObject: arr, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                
                websocket.sendToAI(jsonString, prompt: prompt, wssURL: settings[0].wssURL) { translation in
                    do {
                        // extract valie JSON string from AI reply. Get text between [ ]
                        let regex = try NSRegularExpression(pattern: "\\[(.*?)\\]", options: [])
                        let nsString = translation as NSString
                        let results = regex.matches(in: translation, options: [], range: NSRange(location: 0, length: nsString.length))
                        let r = results.map{ nsString.substring(with: $0.range(at: 1)) }
                        
                        record.locale = locale
                        record.upateFromAI(promptType: settings[0].promptType, summary: "["+r[0]+"]")
                        try? modelContext.save()
                        Task {
                            dismiss()
                        }
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
