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
    @State private var editMode = false
    @State private var showPopup = false
    var record: AudioRecord
    
    @State private var showShareSheet = false
    @State private var isShowingDialog = false  // for Redo confirm dialog

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                DetailSummaryView(editMode: $editMode, record: record, websocket: websocket)
                    .tabItem {
                        VStack {
                            if selectedTab==0 && editMode {
                                Label("Editing", systemImage: "pencil.line")
                            } else {
                                Label("Summary", systemImage: "pencil")
                            }
                        }
                    }
                    .tag(0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "list.bullet")
                        .resizable()
                        .foregroundColor(.primary)
                })
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: {
                    // sharing menu
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                        .foregroundColor(.primary)
                }
                .sheet(isPresented: $showShareSheet, content: {
                    let textToShare = AudioRecord.dateFormatter.string(from: record.recordDate)+": "+record.summary
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
}

#Preview {
    let container = try! ModelContainer(for: AudioRecord.self, Settings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return DetailView(record: AudioRecord.sampleData[0])
        .modelContainer(container)
}
