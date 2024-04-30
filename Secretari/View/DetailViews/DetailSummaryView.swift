//
//  DetailSummaryView.swift
//  Secretari
//
//  Created by 超方 on 2024/4/29.
//

import SwiftUI

struct DetailSummaryView: View {
    @Binding var editMode: Bool
    var record: AudioRecord
    var websocket: Websocket
    @State private var presentRawText = false

    var body: some View {
        NavigationStack {
            HStack {
                Label() {
                    Text(AudioRecord.dateFormatter.string(from: record.recordDate))
                        .font(.subheadline) // Makes the date text larger
                        .foregroundColor(.secondary) // Changes the color of the date text
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundColor(.primary) // Changes the color of the calendar icon
                }
                Spacer()
                
                Button(action: {
                    presentRawText.toggle()
                }, label: {
                    Text("Transcript>>")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                })
            }
            .padding(.horizontal) // Adds horizontal padding to the HStack
            
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
                                print("Edit summary")
                            }, label: {
                                Label("Edit", systemImage: "pencil.line")
                            })
                            Button(action: {
                                print("Regenerate summary")
                            }, label: {
                                Label("Redo", systemImage: "arrow.triangle.2.circlepath")
                            })
                        }))
                        .padding()
                }
            }
        }
        .padding() // Adds padding to the VStack
        .sheet(isPresented: $presentRawText, content: {
            NavigationStack {
                ScrollView {
                    Text(record.transcript)
                        .padding()
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            presentRawText.toggle()
                        }) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        })
    }
}

#Preview {
    DetailSummaryView(editMode: .constant(false), record: AudioRecord.sampleData[0], websocket: Websocket())
}

//                ToolbarItemGroup(placement: .bottomBar) {
//                    Button(action: {
//                        // regenerate AI summary
//                        isShowingDialog = true
//                    }) {
//                        Text("Redo summary")
//                            .padding(5)
//                    }
//                    .foregroundColor(.black)
//                    .background(Color(white: 0.8))
//                    .cornerRadius(5.0)
//                    .shadow(color:.gray, radius: 2, x: 2, y: 2)
//                    .confirmationDialog(
//                        Text("Regenerate summary?"),
//                        isPresented: $isShowingDialog
//                    ) {
//                        Button("Just do it", role: .destructive) {
//                            Task {
//                                self.websocket.sendToAI(record.transcript, settings: self.settings[0]) { summary in
//                                    record.summary = summary
//                                    try? modelContext.save()
//                                }
//                            }
//                        }
//                    }
//                }
