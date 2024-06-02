//
//  SettingsManager.swift
//  Secretari
//
//  Created by 超方 on 2024/5/25.
//

import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    private let defaults = UserDefaults.standard
    private let settingsKey = "UserSettings"
    
    private var settings: Settings {
        didSet {
            saveSettings()
        }
    }

    init() {
        settings = UserDefaultsManager.shared.get(Settings.self, forKey: "appSettings") ?? AppConstants.defaultSettings
    }

    func getSettings() -> Settings {
        return settings
    }

    func updateSettings(_ newSettings: Settings) {
        settings = newSettings
    }

    private func saveSettings() {
        UserDefaultsManager.shared.set(settings, forKey: "appSettings")
    }

    private func loadSettings() -> Settings? {
        UserDefaultsManager.shared.get(Settings.self, forKey: "appSettings")
    }
}

import SwiftData

//@Model
struct Settings :Codable {
    var prompt: [PromptType: [RecognizerLocale : String]]
    var serverURL: String
    var audioSilentDB: String
    var selectedLocale: RecognizerLocale
    var promptType: PromptType       // Two type: Summary and Memo. Memo is a list of bulletins.
    var llmModel: LLMModel
    var llmParams: [LLMModel :Dictionary<String, String>]  // dict that match llm model with respective parameters, which is also a dict.
    
    enum CodingKeys: String, CodingKey {
        case prompt, serverURL, audioSilentDB, selectedLocale, promptType, llmModel, llmParams
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

enum LLM: String, Codable, CaseIterable {
    case OpenAI = "openai"
    case Gemini = "gemini"
}
enum LLMModel: String, Codable, CaseIterable {
    case GPT_3 = "gpt-3.5-turbo"
    case GPT_4 = "gpt-4"
    case GPT_4_Turbo = "gpt-4-turbo"
}

// system constants
final class AppConstants {
    static let MaxSilentSeconds = 1800      // max waiting time if no audio input, 30min
    static let MaxRecordSeconds = 28800     // max working hours, 8hrs
    static let NumRecordsInSwiftData = 30   // number of records kept locally by SwiftData
    static let RecorderTimerFrequency = 10.0  // frequency in seconds to run update() of timer.

    static let DefaultTokenCount = [LLMModel.GPT_3 : UInt(0), LLMModel.GPT_4_Turbo :UInt(0)]
    static let DefaultPassword = "zaq12WSX"
    static let defaultSettings = Settings(prompt: defaultPrompt,
                                          serverURL: "localhost:8000/secretari",
                                          audioSilentDB: "-40",
                                          selectedLocale: Utility.systemLanguage(),
                                          promptType: Settings.PromptType.memo,
                                          llmModel: LLMModel.GPT_4_Turbo,
                                          llmParams: [LLMModel.GPT_4_Turbo: ["llm":"openai", "temperature":"0.0"],
                                                      LLMModel.GPT_3: ["llm":"openai", "temperature":"0.0"]]
    )
    
    static let defaultPrompt = [
        Settings.PromptType.summary: [
            RecognizerLocale.English: "You are a smart assistant. Extract the important content from the following text and make a comprehensive summary. Segment appropriately and correct obvious errors. ",
            RecognizerLocale.中文: "你是個智能秘書。 提取下述文字中的重要內容，做一份全面的摘要。适当分段，并改正明显错误。",
            RecognizerLocale.日本語: "あなたは賢い秘書ですね。 次のテキストから重要な内容を抽出し、包括的な要約を作成します。 適切に分割し、明らかなエラーを修正します。 ",
            RecognizerLocale.Español: "Eres una secretaria inteligente. Extraiga el contenido importante del siguiente texto y haga un resumen completo. Segmente adecuadamente y corrija errores obvios. ",
            RecognizerLocale.Indonesia: "Anda adalah sekretaris yang cerdas. Ekstrak konten penting dari teks berikut dan buatlah ringkasan yang komprehensif. Segmentasikan dengan tepat dan perbaiki kesalahan yang jelas terlihat. ",
        ],
        Settings.PromptType.memo: [
            RecognizerLocale.English: """
            You are a smart assistant. Extract the important content from the rawtext below and make a comprehensive memo. The output format uses the following JSON sequence, where title is the item content of the memo.
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
            RecognizerLocale.日本語: """
            あなたは賢い秘書ですね。 以下の生のテキストから重要な内容を抽出し、包括的なメモを作成します。 出力形式は次の JSON シーケンスを使用します。 ここで、title はメモの項目の内容です。
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
            RecognizerLocale.Español: """
            Eres una secretaria inteligente. Extraiga el contenido importante del texto sin formato a continuación y cree una nota completa. El formato de salida utiliza la siguiente secuencia JSON. Donde título es el contenido del elemento de la nota.
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
            RecognizerLocale.Indonesia: """
            Anda adalah sekretaris yang cerdas. Ekstrak konten penting dari teks mentah di bawah ini dan buatlah memo yang komprehensif. Format keluaran menggunakan urutan JSON berikut. Dimana judul adalah isi item memo tersebut.
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
        ]
    ]
    
}
