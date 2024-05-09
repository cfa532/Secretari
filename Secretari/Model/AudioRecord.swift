//
//  Summary.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/19.
//

import Foundation
import SwiftData

@Model
final class AudioRecord {
    @Attribute(.unique) var recordDate: Date
    
    var transcript: String
    var locale: RecognizerLocale    // language of the transcript
    var translatedLocale: RecognizerLocale?
    var summary: [RecognizerLocale: String]
    var memo: [MemoJsonData]               // array of Json data
    
    init(transcript:String="", summary: [RecognizerLocale:String]=[RecognizerLocale:String]() ) {
        self.recordDate = Date()
        self.transcript = transcript
        self.locale = AppConstants.defaultSettings.selectedLocale
        self.summary = summary
        self.memo = [MemoJsonData]()
    }
    
    func resultFromAI(promptType: Settings.PromptType, summary: String) {
        if promptType == .summary {
            self.summary[self.locale] = summary
        } else {
            do {
                let jsonString = try Utility.getAIJson(aiJson: summary)
                guard let data = jsonString.data(using: .utf8) else {
                    print("Error converting string to data")
                    return
                }
                // Decode the data into an array of dictionaries
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    
                    //                    self.memo = [AudioRecord.MemoJsonData]()      // clear memo which is a dict
                    for item in jsonArray {
                        if let id = item["id"] as? Int,
                           let title = item["title"] as? String,
                           let isChecked = item["isChecked"] as? Bool {

                            if let i = self.memo.firstIndex(where: { $0.id == id }) {
                                //  print("ID: \(t?.id), Title: \(t?.title), isChecked: \(t?.isChecked)")
                                self.memo[i].title[self.locale] = title
                            } else {
                                self.memo.append(AudioRecord.MemoJsonData(id: id, title: [self.locale :title], isChecked: isChecked))
                            }
                        }
                    }
                } else {
                    print("Error decoding JSON")
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }
    }
}

extension AudioRecord {
    static let sampleData: [AudioRecord] =
    [
        AudioRecord(transcript: "Vodka is a clear distilled alcoholic beverage. Different varieties originated in Poland, Russia, and Sweden.\n\n 少子化代表着未来人口可能逐渐变少，对于社会结构、经济发展等各方面都会产生重大影响。如果新一代增加的速度远低于上一代自然死亡的速度，更会造成人口不足，所以少子化是许多国家（特别是发达国家）非常关心的问题。",
                    summary: [.English :"Vodka is a clear distilled alcoholic beverage."])
    ]
    
    struct MemoJsonData: Codable, Identifiable {
        @Attribute(.unique) let id: Int
        var title: [RecognizerLocale: String]
        var isChecked: Bool
    }
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
    
    static let dateLongFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter
    }()
}
