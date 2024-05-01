//
//  DetailEditView.swift
//  Secretari
//
//  Created by 超方 on 2024/4/30.
//

import SwiftUI

struct DetailEditView: View {
    @Binding var record: AudioRecord
    @State private var temp: String = ""
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        NavigationStack {
            Form {
                TextField( record.summary, text: $temp, axis: .vertical )
                    .lineLimit(.max)
            }
            .onAppear(perform: {
                if temp == "" {
                    temp = record.summary
                }
            })
        }
        .navigationTitle("Edit Summary")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    record.summary = temp
                } label: {
                    Text("Save")
                }
            }
        }
    }
}

#Preview {
    DetailEditView(record: .constant(AudioRecord.sampleData[0]))
}
