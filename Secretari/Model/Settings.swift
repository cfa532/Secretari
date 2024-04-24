//
//  Settings.swift
//  Secretari
//
//  Created by 超方 on 2024/4/24.
//

import Foundation
import SwiftData

@Model
final class Settings {
    var prompt: String
    var wssURL: String
    var audioSilentDB: String
    var speechLocale: RecognizerLocals
    
    init(prompt: String, wssURL: String, audioSilentDB: String, speechLocale: RecognizerLocals ) {
        self.prompt = prompt
        self.wssURL = wssURL
        self.audioSilentDB = audioSilentDB
        self.speechLocale = speechLocale
    }
}

enum RecognizerLocals: String, CaseIterable, Codable {
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
    static let RecorderTimerFrequency = 10.0  // frequency in seconds to run update() of timer.
    static let OpenAIModel = "gpt-4"
    static let OpenAITemperature = "0.0"
    static let LLM = "openai"
    static let defaultSettings = Settings(prompt: NSLocalizedString("You are a smart assistant. Generate a comprehensive summary from the following speech.", comment: ""),
                                          wssURL: "wss://leither.uk/ws",
                                          audioSilentDB: "-40",
                                          speechLocale: Localized.systemLanguage()
    )
    
    static private func localizedPrompt() -> String {
        switch NSLocale.current.language.languageCode?.identifier {
        case "zh":
            return "你是個智能秘書。 提取下述文字中的重要內容，做一份全面的摘要。"
        case "ja":
            return "あなたは賢いアシスタントです。 次のスピーチから包括的な要約を作成します。"
        default:
            return "You are a smart assistant. Generate a comprehensive summary from the following speech."
        }
        
    }
}
