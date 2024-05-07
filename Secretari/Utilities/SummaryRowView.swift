//
//  SummaryRowView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/7.
//

import SwiftUI

struct SummaryRowView: View {
    var record: AudioRecord
    var promptType: Settings.PromptType
    
    var body: some View {
        let curDate: String = AudioRecord.dateFormatter.string(from: record.recordDate)
        let title = curDate + ": "
        
        // display content based on prompt type
        if promptType == .memo {
            if record.memo.isEmpty {
                Text(title + record.summary)
                    .font(.subheadline)
                    .lineLimit(4)
            } else {
                Text(title + record.memo[0].title)
                    .font(.subheadline)
                    .lineLimit(4)
                    .onAppear(perform: {

                    })
            }
        } else {
            if record.summary != "" {
                Text(title + record.summary)
                    .font(.subheadline)
                    .lineLimit(4)
            } else {
                Text(title + record.memo[0].title)
                    .font(.subheadline)
                    .lineLimit(4)
            }
        }
    }
}

#Preview {
    SummaryRowView(record: AudioRecord.sampleData[0], promptType: Settings.PromptType.memo)
}
