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
    var prompt: [PromptType: [RecognizerLocale : String]]
    var wssURL: String
    var audioSilentDB: String
    var selectedLocale: RecognizerLocale
    var promptType: PromptType       // Two type: Summary and Memo. Memo is a list of bulletins.
    
    init(prompt: [PromptType: [RecognizerLocale : String]], wssURL: String, audioSilentDB: String, selectedLocale: RecognizerLocale, promptType: PromptType) {
        self.prompt = prompt
        self.wssURL = wssURL
        self.audioSilentDB = audioSilentDB
        self.selectedLocale = selectedLocale
        self.promptType = promptType
    }
    
    enum PromptType: String, CaseIterable, Codable {
        case summary, memo
        var id: Self { self }
    }
}

enum RecognizerLocale: String, CaseIterable, Codable {
    case English = "en"
    case 日本語 = "ja"
    case 中文 = "zh"
    case Español = "es"     // Latin Spanish
    case Indonesia = "id"
    // fr, sp,
    var id: Self { self }
}

// system constants
final class AppConstants {
    static let MaxSilentSeconds = 1800      // max waiting time if no audio input, 30min
    static let MaxRecordSeconds = 28800     // max working hours, 8hrs
    static let NumRecordsInSwiftData = 30   // number of records kept locally by SwiftData
    static let RecorderTimerFrequency = 10.0  // frequency in seconds to run update() of timer.
    static let OpenAIModel = "gpt-4-turbo"
    static let OpenAITemperature = "0.0"
    static let LLM = "openai"
    static let defaultSettings = Settings(prompt: defaultPrompt,
                                          wssURL: "wss://leither.uk/ws",
                                          audioSilentDB: "-40",
                                          selectedLocale: Localized.systemLanguage(),
                                          promptType: Settings.PromptType.memo)
    
    static let defaultPrompt = [
        Settings.PromptType.summary: [
            RecognizerLocale.English: "You are a smart assistant. Generate a comprehensive summary from the following speech.",
            RecognizerLocale.中文: "你是個智能秘書。 提取下述文字中的重要內容，做一份全面的摘要。适当分段，并改正明显错误。",
            RecognizerLocale.日本語: "あなたは賢いアシスタントです。 次のスピーチから包括的な要約を作成します。",
            RecognizerLocale.Español: "Eres un asistente inteligente. Genere un resumen completo del siguiente discurso.",
            RecognizerLocale.Indonesia: "Anda adalah asisten yang cerdas. Hasilkan ringkasan komprehensif dari pidato berikut.",
        ],
        Settings.PromptType.memo: [
            RecognizerLocale.English: "You are a smart assistant. Generate a comprehensive summary from the following speech.",
            RecognizerLocale.中文: """
            你是個智能秘書。 提取下述 rawtext 中的重要內容，做一份全面的备忘录。輸出格式採用下述 JSON 序列。其中 title 是備忘錄的條目內容。
            [
              {
                "id": 1,
                "title": "Item 1",
                "isChecked": false
              },
              {
                "id": 2,
                "title": "Item 2",
                "isChecked": false
              },
              {
                "id": 3,
                "title": "Item 3",
                "isChecked": false
              }
            ]
            
            rawtext:
            
            """,
            RecognizerLocale.日本語: "あなたは賢いアシスタントです。 次のスピーチから包括的な要約を作成します。",
            RecognizerLocale.Español: "Eres un asistente inteligente. Genere un resumen completo del siguiente discurso.",
            RecognizerLocale.Indonesia: "Anda adalah asisten yang cerdas. Hasilkan ringkasan komprehensif dari pidato berikut.",
        ]
    ]
    
}
