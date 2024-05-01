//
//  DetailSummaryView.swift
//  Secretari
//
//  Created by 超方 on 2024/4/29.
//

import SwiftUI
import SwiftData

struct DetailSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
//    @Query(sort: \AudioRecord.recordDate, order: .reverse) var records: [AudioRecord]

    @Binding var record: AudioRecord
    @StateObject private var websocket = Websocket()

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
//                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(3)
                    Text( record.summary )
                        .onTapGesture(perform: {
                            print("Enter Summary view")
                        })
                        .contextMenu(ContextMenu(menuItems: {
                            Button(action: {
                                print("Regenerate summary")
                                websocket.sendToAI(record.transcript, prompt: settings[0].prompt[settings[0].selectedLocale]!, wssURL: settings[0].wssURL) { summary in
                                    record.summary = summary
                                }
                            }, label: {
                                Label("Redo summary", systemImage: "arrow.triangle.2.circlepath")
                            })
                        }))
//                        .padding()
                }
            }
        }
        .padding() // Adds padding to the VStack
    }
}

#Preview {
    DetailSummaryView(record: .constant(AudioRecord.sampleData[0]))
}
