//
//  DetailSummaryView.swift
//  Secretari
//
//  Created by 超方 on 2024/4/29.
//

import SwiftUI

struct DetailSummaryView: View {
    var record: AudioRecord
    var websocket: Websocket

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
                } else {
                    Text( record.summary )
                        .onTapGesture(perform: {
                            print("Enter Summary view")
                        })
                        .contextMenu(ContextMenu(menuItems: {
                            Button(action: {
                                print("Regenerate summary")
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
    DetailSummaryView(record: AudioRecord.sampleData[0], websocket: Websocket())
}
