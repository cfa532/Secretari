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
    var summary: String
    var translation: [Language: String]     // array of Language type and corresponding translation
    var memo: [MemoJsonData]               // array of Json data
    
    init(transcript: String="", summary: String="") {
        self.recordDate = Date()
        self.transcript = transcript
        self.summary = summary
        self.translation = [Language: String]()
        self.memo = [MemoJsonData]()
    }
    
    struct MemoJsonData: Codable, Identifiable {
        @Attribute(.unique) let id: Int
        let title: String
        var isChecked: Bool
    }
}

extension AudioRecord {
    static let sampleData: [AudioRecord] =
    [
        AudioRecord(transcript: "Vodka is a clear distilled alcoholic beverage. Different varieties originated in Poland, Russia, and Sweden.\n\n 少子化代表着未来人口可能逐渐变少，对于社会结构、经济发展等各方面都会产生重大影响。如果新一代增加的速度远低于上一代自然死亡的速度，更会造成人口不足，所以少子化是许多国家（特别是发达国家）非常关心的问题。",
                    summary: "Vodka is a clear distilled alcoholic beverage.")
    ]
    
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

    enum Language: String, CaseIterable, Codable  {
        case English, Filipino, Indonesia
    }
}
