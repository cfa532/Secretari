//
//  LocalePicker.swift
//  Secretari
//
//  Created by 超方 on 2024/5/8.
//

import SwiftUI

struct LocalePicker: View {
    var promptType: Settings.PromptType
    @Binding var record: AudioRecord
    
    var body: some View {
        if promptType == .summary {
            if !record.summary.isEmpty {
                Picker(" ", selection: $record.locale) {
                    ForEach(record.summary.keys.sorted(by: { a, b in
                        String(describing: a) < String(describing: b)
                    }), id: \.id) { key in
                        Text(String(describing: key))
                    }
                }
                .opacity(record.summary.keys.count<2 ? 0 : 1)
            } else {
                Picker("", selection: $record.locale) {
                    ForEach(record.memo[0].title.keys.sorted(by: { a, b in
                        String(describing: a) < String(describing: b)
                    }), id: \.id) { key in
                        Text(String(String(describing: key)))
                    }
                }
                .opacity(record.memo[0].title.keys.count<2 ? 0 : 1)
            }
        }
        else {
            if !record.memo.isEmpty {
                Picker("", selection: $record.locale) {
                    ForEach(record.memo[0].title.keys.sorted(by: { a, b in
                        String(describing: a) < String(describing: b)
                    }), id: \.id) { key in
                        Text(String(String(describing: key)))
                    }
                }
                .opacity(record.memo[0].title.keys.count<2 ? 0 : 1)
            } else {
                Picker(" ", selection: $record.locale) {
                    ForEach(record.summary.keys.sorted(by: { a, b in
                        String(describing: a) < String(describing: b)
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
    LocalePicker(promptType: .memo, record: .constant(AudioRecord.sampleData[0]))
}
