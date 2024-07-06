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
        settings = UserDefaultsManager.shared.get(for: "appSettings", type: Settings.self) ?? AppConstants.defaultSettings
    }
    
    func getSettings() -> Settings {
        return settings
    }
    
    func updateSettings(_ newSettings: Settings) {
        settings = newSettings
    }
    
    private func saveSettings() {
        UserDefaultsManager.shared.set(settings, for: "appSettings")
    }
    
    private func loadSettings() -> Settings? {
        UserDefaultsManager.shared.get(for: "appSettings", type: Settings.self)
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
    //    var llmModel: LLMModel
    var llmParams: [String: String]  // llm parameters
    
    enum CodingKeys: String, CodingKey {
        case prompt, serverURL, audioSilentDB, selectedLocale, promptType, llmParams
    }
    
    enum PromptType: String, CaseIterable, Codable {
        case summary = "summary"
        case checklist = "checklist"
        var id: Self { self }
        
        // when non-subscriber get low balance, only summary type is allowed.
        static func allowedCases(lowBalance: Bool) -> [Settings.PromptType] {
            if lowBalance {
                // set prompt to summary type too.
                return [.summary]
            } else {
                return PromptType.allCases
            }
        }
    }
}

enum RecognizerLocale: String, CaseIterable, Codable {
    case English = "en"
    case 日本語 = "ja"
    case 中文 = "zh"
    case Español = "es"     // Latin Spanish
    case Indonesia = "id"
    case 한국인 = "ko"
    case Filipino = "fil"
    case ViệtNam = "vi"
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
    case GPT_4o = "gpt-4o"
}

// system constants
final class AppConstants {
    static let MaxSilentSeconds = 1800      // max waiting time if no audio input, 30min
    static let MaxRecordSeconds = 28800     // max working hours, 8hrs
    static let NumRecordsInSwiftData = 30   // number of records kept locally by SwiftData
    static let RecorderTimerFrequency = 10.0  // frequency in seconds to run update() of timer.
    
    static let PrimaryModel = LLMModel.GPT_4o      //
    static let SignupBonus = 0.2                // the initial dollar balance to give user for free trial.
    static let DefaultPassword = "zaq12WSX"
    static let defaultSettings = Settings(prompt: defaultPrompt,
                                          serverURL: "leither.uk/secretari",
                                          audioSilentDB: "-40",
                                          selectedLocale: Utility.systemLanguage(),
                                          promptType: Settings.PromptType.checklist,
                                          llmParams: ["llm":"openai", "temperature":"0.0"]
    )
    
    static let defaultPrompt = [
        Settings.PromptType.summary: [
            RecognizerLocale.English: "You are an intelligent secretary. Extract the important content from the following text and make a comprehensive summary. Divide it into appropriate sections. The output format should be plain text. ",
            RecognizerLocale.中文: "你是個智能秘書。 提取下述文字中的重要內容，做一份全面的摘要。并适当分段。输出格式用纯文本。",
            RecognizerLocale.日本語: "あなたはインテリジェントな秘書です。以下のテキストから重要な内容を抽出し、包括的な要約を作成してください。適切に段落を分けてください。出力形式はプレーンテキストでお願いします。",
            RecognizerLocale.Español: "Eres un secretario inteligente. Extrae el contenido importante del siguiente texto y haz un resumen completo. Divide el texto en secciones apropiadas. El formato de salida debe ser texto plano. ",
            RecognizerLocale.Indonesia: "Anda adalah sekretaris cerdas. Ekstrak konten penting dari teks berikut dan buat ringkasan yang komprehensif. Silakan bagi menjadi beberapa bagian yang sesuai. Format keluaran harus dalam teks biasa. ",
            RecognizerLocale.한국인: "당신은 똑똑한 비서입니다. 다음 텍스트에서 중요한 내용을 추출하여 포괄적인 요약을 작성하세요. 적절한 섹션으로 나누세요. ",
        ],
        Settings.PromptType.checklist: [
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
            RecognizerLocale.한국인: """
            당신은 똑똑한 조수입니다. 아래 원문에서 중요한 내용을 추출하여 종합적인 메모를 작성해 보세요. 출력 형식은 다음 JSON 시퀀스를 사용합니다. 여기서 제목은 메모의 항목 내용입니다.
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

            """
        ]
    ]
}
