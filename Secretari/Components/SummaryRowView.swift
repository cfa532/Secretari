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
        let title = AudioRecord.dateFormatter.string(from: record.recordDate) + ": "
        
        VStack {
            // display content based on prompt type
            if promptType == .memo {
                if !record.memo.isEmpty {
                    Text(title + concateMemo())
                        .lineLimit(4)
                } else {
                    Text(title + (record.summary[record.locale] ?? "No summary."))
                        .lineLimit(4)
                }
            } else {
                // prompt type is Summary
                if !record.summary.isEmpty {
                    Text(title + (record.summary[record.locale] ?? "No summary."))
                        .lineLimit(4)
                } else {
                    Text(title + concateMemo())
                        .lineLimit(4)
                }
            }
        }
    }
    
    func concateMemo()->String {
        var title = ""
        for item in record.memo {
            title.append((item.isChecked ? "☑ " : "☐ ") + (item.title[record.locale] ?? ": No record.") + " ")
        }
        return title // Remove trailing whitespace
    }
}

#Preview {
    SummaryRowView(record: AudioRecord.sampleData[0], promptType: Settings.PromptType.memo)
}
