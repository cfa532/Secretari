//
//  LocalePicker.swift
//  Secretari
//
//  Created by 超方 on 2024/5/8.
//

import SwiftUI

// set the Locles used in the Picker view
struct LocalePicker: View {
    var promptType: Settings.PromptType
    @Binding var record: AudioRecord
    
    var body: some View {
        if promptType == .summary {
            if !record.summary.isEmpty {
                Picker(" ", selection: $record.locale) {
                    ForEach(record.summary.keys.sorted(by: { a, b in
                        a.rawValue < b.rawValue
                    }), id: \.id) { key in
                        Text(String(describing: key))
                    }
                }
                .opacity(record.summary.keys.count<2 ? 0 : 1)
            } else {
                if let memo = record.memo.first {
                    Picker(" ", selection: $record.locale) {
                        ForEach(memo.title.keys.sorted(by: { a, b in
                            a.rawValue < b.rawValue
                        }), id: \.id) { key in
                            Text(String(String(describing: key)))
                        }
                    }
                    .opacity(memo.title.keys.count<2 ? 0 : 1)
                }
            }
        }
        else {
            if !record.memo.isEmpty {
                if let memo = record.memo.first {
                    Picker(" ", selection: $record.locale) {
                        ForEach(memo.title.keys.sorted(by: { a, b in
                            a.rawValue < b.rawValue
                        }), id: \.id) { key in
                            Text(String(String(describing: key)))
                        }
                    }
                    .opacity(memo.title.keys.count<2 ? 0 : 1)
                }
            } else {
                Picker(" ", selection: $record.locale) {
                    ForEach(record.summary.keys.sorted(by: { a, b in
                        a.rawValue < b.rawValue
                    }), id: \.id) { key in
                        Text(String(describing: key))
                    }
                }
                .opacity(record.summary.keys.count<2 ? 0 : 1)
            }
        }
    }
}

#Preview {
    LocalePicker(promptType: .checklist, record: .constant(AudioRecord.sampleData[0]))
}
