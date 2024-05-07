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
                    CheckboxView(label: item.title, isChecked: Binding(get:{item.isChecked}, set:{newValue in
                        if let index = record.memo.firstIndex(where: {$0.id == item.id}) {
                            record.memo[index].isChecked = newValue
                        }
                    }))
                }
                .padding(5)
            }
        }
        .onAppear(perform: {
            // Convert the JSON string to data
            if record.memo.isEmpty {
                guard let data = record.summary.data(using: .utf8) else {
                    print("Error converting string to data")
                    return
                }
                do {
                    // Decode the data into an array of dictionaries
                    if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                        // Process the decoded array here
                        for item in jsonArray {
                            if let id = item["id"] as? Int,
                               let title = item["title"] as? String,
                               let isChecked = item["isChecked"] as? Bool {
                                // Access and use the data from each dictionary item
                                print("ID: \(id), Title: \(title), isChecked: \(isChecked)")
                                record.memo.append(AudioRecord.MemoJsonData(id: id, title: title, isChecked: isChecked))
                            }
                        }
                    } else {
                        print("Error decoding JSON")
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                }            }
        })
    }
}

#Preview {
    DetailBulletinView(record: .constant(AudioRecord.sampleData[0]))
}
