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
    @Environment(\.dismiss) var dismiss
    
    @State private var alertItem: AlertItem?
    @State private var showShareSheet = false
    @State private var settings: Settings = SettingsManager.shared.getSettings()
    @StateObject private var websocket = Websocket.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                if websocket.isStreaming {
                    ScrollViewReader { proxy in
                        let message = websocket.streamedText
                        Label {
                            DotAnimationView(title: "Streaming from AI")
                        } icon: {
                            Image(systemName: "brain.head.profile.fill")
                        }
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
                        Text(LocalizedStringKey("Select one of the following languages to translate the Summary. If summary exists, it will be overwritten."))
                        Button(LocalizedStringKey("English")) {
                            if settings.promptType == .checklist {
                                translateMemo(locale: .English, record: record, prompt: "The following text is a valid JSON string. Translate the content of title attribute of the JSON object into English. Only return a pure JSON string in the same format. ")
                            } else {
                                translateSummary(locale: .English, record: record, prompt: "Translate the following text into English. Export with plain text. ")
                            }
                        }
                        Button("中文") {
                            if settings.promptType == .checklist {
                                translateMemo(locale: .中文, record: record, prompt: "以下文字是有效的 JSON 字串。將 JSON 物件的 title 屬性內容翻譯成繁體中文。只傳回相同格式的純JSON字串。 ")
                            } else {
                                translateSummary(locale: .中文, record: record, prompt: "將下面的文字翻譯成繁體中文。以純文字導出。 ")
                            }
                        }
                        Button(LocalizedStringKey("Indonesia")) {
                            if settings.promptType == .checklist {
                                translateMemo(locale: .Indonesia, record: record, prompt: "Teks berikut adalah string JSON yang valid. Terjemahkan judul setiap objek JSON ke dalam bahasa Indonesia. Hanya kembalikan string JSON murni dalam format yang sama. ")
                            } else {
                                translateSummary(locale: .Indonesia, record: record, prompt: "Terjemahkan teks berikut ke dalam bahasa Indonesia. Ekspor dengan teks biasa.")
                            }
                        }
                        Button("日本語🇯🇵") {
                            if settings.promptType == .checklist {
                                translateMemo(locale: .日本語, record: record, prompt: "次のテキストは有効な JSON 文字列です。JSON オブジェクトの title 属性の内容を日本語に翻訳します。同じ形式の純粋な JSON 文字列のみを返します。 ")
                            } else {
                                translateSummary(locale: .日本語, record: record, prompt: "次のテキストを日本語に翻訳し、プレーンテキストでエクスポートします。 ")
                            }
                        }
                        Button(LocalizedStringKey("Việt Nam🇻🇳")) {
                            if settings.promptType == .checklist {
                                translateMemo(locale: .ViệtNam, record: record, prompt: "Văn bản sau đây là một chuỗi JSON hợp lệ. Dịch nội dung thuộc tính title của đối tượng JSON sang tiếng việt. Chỉ trả về một chuỗi JSON thuần túy có cùng định dạng. ")
                            } else {
                                translateSummary(locale: .ViệtNam, record: record, prompt: "Dịch đoạn văn sau sang tiếng Việt. Xuất với văn bản thuần túy. ")
                            }
                        }
                        Button(LocalizedStringKey("Filipino🇵🇭")) {
                            if settings.promptType == .checklist {
                                translateMemo(locale: .Filipino, record: record, prompt: "Ang sumusunod na text ay isang wastong JSON string. Isalin sa Filipino ang nilalaman ng katangian ng pamagat ng object ng JSON. Magbalik lang ng purong JSON string sa parehong format. ")
                            } else {
                                translateSummary(locale: .Filipino, record: record, prompt: "Isalin sa Filipino ang sumusunod na teksto. I-export gamit ang plain text. ")
                            }
                        }
                        Button("แบบไทย🇹🇭") {
                            if settings.promptType == .checklist {
                                translateMemo(locale: .แบบไทย, record: record, prompt: "ข้อความต่อไปนี้เป็นสตริง JSON ที่ถูกต้อง แปลเนื้อหาของแอตทริบิวต์ title ของออบเจ็กต์ JSON เป็นภาษาไทย ส่งคืนสตริง JSON แท้ในรูปแบบเดียวกันเท่านั้น ")
                            } else {
                                translateSummary(locale: .แบบไทย, record: record, prompt: "แปลข้อความต่อไปนี้เป็นภาษาไทย ส่งออกด้วยข้อความธรรมดา ")
                            }
                        }
                    })
                }
            }
            .padding()
        }
        .navigationTitle(LocalizedStringKey("Translation"))
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
    
    @MainActor private func translateSummary(locale: RecognizerLocale, record: AudioRecord, prompt: String) {
        if let summary = record.summary[record.locale] {
            // use Summary of orginal local as source to translate.
            websocket.sendToAI(summary, prompt: prompt) { result in
                record.locale = locale      // change current locale to the last selectedLocale
                record.summary[locale] = result
                try? modelContext.save()
                Task {
                    dismiss()
                }
            }
        } else {
            self.alertItem = AlertContext.emptySummary
        }
    }
    
    @MainActor private func translateMemo(locale: RecognizerLocale, record: AudioRecord, prompt: String) {
        do {
            var arr:[Any] = [Any]()
            if !record.memo.isEmpty {
                for m in record.memo {
                    if let title = m.title[record.locale] {
                        arr.append(["id":m.id, "title": String(describing: title), "isChecked":m.isChecked])
                    }
                }
            } else {
                // no memo for the record, create one from its summary
                print("No memo to print")
                self.alertItem = AlertContext.emptyMemo
                
            }
            let jsonData = try JSONSerialization.data(withJSONObject: arr, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                
                websocket.sendToAI(jsonString, prompt: prompt) { result in
                    do {
                        record.locale = locale
                        record.resultFromAI(taskType: .translate, summary: try Utility.getAIJson(aiJson: result))
                        try? modelContext.save()
                        Task {
                            dismiss()
                        }
                    } catch let error {
                        print("Invalid regex:", error.logDescription)
                        self.alertItem = AlertContext.invalidJSON
                    }
                }
            } else {
                print("Failed to convert data to string.")
                self.alertItem = AlertContext.invalidJSON
            }
        } catch {
            print("Error converting JSON object to Data:", error.logDescription)
            self.alertItem = AlertContext.invalidJSON
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
