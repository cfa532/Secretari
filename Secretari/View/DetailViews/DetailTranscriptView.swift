//
//  DetailTranscriptView.swift
//  Secretari
//
//  Created by 超方 on 2024/4/30.
//

import SwiftUI

struct DetailTranscriptView: View {
    var record: AudioRecord
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(AudioRecord.dateLongFormat.string(from: record.recordDate))
                    .padding(3)
                Text(record.transcript)
            }
        }
        .padding()
        .navigationTitle("Transcript")
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
}

#Preview {
    DetailTranscriptView(record: AudioRecord.sampleData[0])
}
