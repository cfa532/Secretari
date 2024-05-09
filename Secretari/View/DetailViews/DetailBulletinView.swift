//
//  DetailBulletinView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/7.
//

import SwiftUI

struct DetailBulletinView: View {
    @Binding var record: AudioRecord
    
    var body: some View {
        NavigationStack {
            ForEach(record.memo) { item in
                HStack {
                    CheckboxView(
                        label: Binding(
                            get: {item.title[record.locale] ?? "No record. Try to regenerate summary"},
                            set: { newValue in
                                if let index = record.memo.firstIndex(where: {$0.id == item.id}) {
                                    record.memo[index].title[record.locale] = newValue
                                }
                            }),
                        isChecked: Binding(
                            get:{item.isChecked},
                            set:{newValue in
                                if let index = record.memo.firstIndex(where: {$0.id == item.id}) {
                                    record.memo[index].isChecked = newValue
                                }
                            }))
                }
                .padding(5)
            }
        }
    }
}

#Preview {
    DetailBulletinView(record: .constant(AudioRecord.sampleData[0]))
}
