//
//  DetailEditView.swift
//  Secretari
//
//  Created by 超方 on 2024/4/30.
//

import SwiftUI

struct DetailEditView: View {
    @Binding var record: AudioRecord
    
    var body: some View {
        NavigationStack {
            Form {
                TextField( record.summary, text: $record.summary, axis: .vertical )
                    .lineLimit(.max)
            }
        }
        .navigationTitle("Edit Summary")
//        .padding() // Adds padding to the VStack
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    print("cancel")
                } label: {
                    Text("Cancel")
                }
            }
        }
    }
}

#Preview {
    DetailEditView(record: .constant(AudioRecord.sampleData[0]))
}
