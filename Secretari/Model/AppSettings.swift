//
//  Settings.swift
//  SummarySwiftData
//
//  Created by 超方 on 2024/4/16.
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    var prompt: String
    var wssURL: String
    var audioSilentDB: String
    var speechLocale: String
    
    init(prompt: String, wssURL: String, audioSilentDB: String, speechLocale: String ) {
        self.prompt = prompt
        self.wssURL = wssURL
        self.audioSilentDB = audioSilentDB
        self.speechLocale = speechLocale
    }
}

extension AppSettings {
    static let defaultSettings = AppSettings(prompt: "你是一个智能秘书。提取下述文字中的重要内容，生成一份备忘录。",
                                             wssURL: "wss://leither.uk/ws",
                                             audioSilentDB: "-40",
                                             speechLocale: RecognizerLocals.Chinese.rawValue
//                                             speechLocale: Locale.current.identifier
    )
}

enum RecognizerLocals: String, CaseIterable, Identifiable {
    case English = "en_US"
    case Japanese = "ja_JP"
    case Chinese = "zh_CN"
    
    var id: Self { self }
}

// system constants
final class AppConstants {
    static let MaxSilentSeconds = 1800      // max waiting time if no audio input, 30min
    static let MaxRecordSeconds = 28800     // max working hours, 8hrs
    static let NumRecordsInSwiftData = 30   // number of records kept locally by SwiftData
    static let OpenAIModel = "gpt-4"
    static let OpenAITemperature = "0.0"
    static let LLM = "openai"
}
