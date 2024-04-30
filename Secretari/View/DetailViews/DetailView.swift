//
//  DetailView.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/29.
//

import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @Query private var settings: [Settings]
    @StateObject private var websocket = Websocket()
    @State private var selectedTab = 0
    @State private var viewMode = DetailViewMode.Summary
    @State private var showPopup = false
    @State var record: AudioRecord
    
    @State private var showShareSheet = false
    @State private var isShowingDialog = false  // for Redo confirm dialog
    @State private var presentRawText = false
    
    var body: some View {
        NavigationStack {
            switch viewMode {
            case .Edit:
                DetailEditView(record: $record)
            case .Transcript:
                Text("Edit")
            case .Translation:
                Text("Edit")
            default:
                DetailSummaryView(record: record, websocket: websocket)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle(AudioRecord.dateFormatter.string(from: record.recordDate))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "list.bullet")
                        .resizable()
                })
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu(content: {
                    Button {
                        print("show share meun")
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        print("show raw transcript")
                        presentRawText.toggle()
                    } label: {
                        Label("Transcript", systemImage: "text.word.spacing")
                    }
                    Button {
                        print("edit summary")
                        viewMode = .Edit
                    } label: {
                        Label("Edit", systemImage: "pencil.line")
                    }
                    Menu("Translations", systemImage: "square.fill.text.grid.1x2") {
                        Button {
                            print("Translate to English")
                        } label: {
                            Text("English")
                        }
                        Button {
                            print("Translate to English")
                        } label: {
                            Text("English")
                        }
                    }
                }, label: {
                    Image(systemName: "ellipsis")
                        .resizable()
                })
                .sheet(isPresented: $showShareSheet, content: {
                    let textToShare = AudioRecord.dateFormatter.string(from: record.recordDate)+": "+record.summary
                    ShareSheet(activityItems: [textToShare])
                })
            }
        })
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
    
    struct ShareSheet: UIViewControllerRepresentable {
        let activityItems: [Any]
        func makeUIViewController(context: Context) -> UIActivityViewController {
            return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        }
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
    
    enum DetailViewMode {
        case Summary, Edit, Transcript, Translation
    }
}

#Preview {
    let container = try! ModelContainer(for: AudioRecord.self, Settings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return DetailView(record: AudioRecord.sampleData[0])
        .modelContainer(container)
}
