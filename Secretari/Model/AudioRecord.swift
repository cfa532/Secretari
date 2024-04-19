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
    
    init(transcript: String, summary: String) {
        self.recordDate = Date()
        self.transcript = transcript
        self.summary = summary
    }
}

extension AudioRecord {
    static let sampleData: [AudioRecord] =
    [
        AudioRecord(transcript: "Vodka is a clear distilled alcoholic beverage. Different varieties originated in Poland, Russia, and Sweden",
                    summary: "Vodka is a clear distilled alcoholic beverage.")
    ]
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
}
