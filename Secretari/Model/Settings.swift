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
    var prompt: [RecognizerLocale : String]
    var wssURL: String
    var audioSilentDB: String
    var selectedLocale: RecognizerLocale
    
    init(prompt: [RecognizerLocale : String], wssURL: String, audioSilentDB: String, speechLocale: RecognizerLocale ) {
        self.prompt = prompt
        self.wssURL = wssURL
        self.audioSilentDB = audioSilentDB
        self.selectedLocale = speechLocale
    }
}

enum RecognizerLocale: String, CaseIterable, Codable {
    case English = "en"
    case Japanese = "ja"
    case Chinese = "zh"

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
    static let defaultSettings = Settings(prompt: defaultPromot,
                                          wssURL: "wss://leither.uk/ws",
                                          audioSilentDB: "-40",
                                          speechLocale: Localized.systemLanguage()
    )
    
    static private func localizedPrompt() -> String {
        switch NSLocale.current.language.languageCode?.identifier {
        case "zh":
            return "你是個智能秘書。 提取下述文字中的重要內容，做一份全面的摘要。"
        case "ja":
            return "あなたは賢いアシスタントです。 次のスピーチから包括的な要約を作成する。"
        default:
            return "You are a smart assistant. Generate a comprehensive summary from the following speech."
        }
        
    }
    
    static let defaultPromot = [
        RecognizerLocale.English: "You are a smart assistant. Generate a comprehensive summary from the following speech.",
        RecognizerLocale.Chinese: "你是個智能秘書。 提取下述文字中的重要內容，做一份全面的摘要。",
        RecognizerLocale.Japanese: "あなたは賢いアシスタントです。 次のスピーチから包括的な要約を作成します。"
    ]
}
