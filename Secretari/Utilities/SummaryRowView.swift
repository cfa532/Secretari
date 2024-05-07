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
                Text(title + (record.summary[record.locale] ?? "No summary"))
                    .font(.subheadline)
                    .lineLimit(4)
            } else {
                let memo = record.memo[0]
                Text(title + memo.title[record.locale]!)
                    .font(.subheadline)
                    .lineLimit(4)
                    .onAppear(perform: {

                    })
            }
        } else {
            // prompt type is Summary
            if record.summary.isEmpty {
                Text(title + record.memo[0].title[record.locale]!)
                    .font(.subheadline)
                    .lineLimit(4)
            } else {
                Text(title + record.summary[record.locale]!)
                    .font(.subheadline)
                    .lineLimit(4)
            }
        }
    }
}

#Preview {
    SummaryRowView(record: AudioRecord.sampleData[0], promptType: Settings.PromptType.memo)
}
