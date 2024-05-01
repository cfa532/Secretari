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
//    @Environment(\.modelContext) private var modelContext
//    @Query private var settings: [Settings]
    
    @StateObject private var websocket = Websocket()
    @State private var viewMode = DetailViewMode.Summary
    @State private var showPopup = false
    @State var record: AudioRecord
    
    @State private var showShareSheet = false
    @State private var isShowingDialog = false  // for Redo confirm dialog
    
    var body: some View {
        NavigationStack {
            DetailSummaryView(record: record, websocket: websocket)
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Summary")
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
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    NavigationLink(destination: DetailTranscriptView(record: record)) {
                        Label("Transcript", systemImage: "text.word.spacing")
                    }
                    NavigationLink(destination: DetailEditView(record: $record)) {
                        Label("Edit", systemImage: "pencil.line")
                    }
                    NavigationLink(destination: DetailTranslationView(record: $record)) {
                        Label("Translation", systemImage: "textformat.abc.dottedunderline")
                    }
                }, label: {
                    Image(systemName: "ellipsis")
                        .resizable()
                })
                .sheet(isPresented: $showShareSheet, content: {
                    let textToShare = AudioRecord.dateLongFormat.string(from: record.recordDate)+": "+record.summary
                    ShareSheet(activityItems: [textToShare])
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
    
    enum DetailViewMode {
        case Summary, Edit, Transcript, Translation
    }
}

#Preview {
    DetailView(record: (AudioRecord.sampleData[0]))
//    let container = try! ModelContainer(for: AudioRecord.self, Settings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
//    return DetailView(record: AudioRecord.sampleData[0])
//        .modelContainer(container)
}
