//
//  SettingsManager.swift
//  Secretari
//
//  Created by 超方 on 2024/5/25.
//

import Foundation
import SwiftData

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
    /// Updates the current settings with new settings.
    func updateSettings(_ newSettings: Settings) {
        settings = newSettings
    }
    /// Saves the current settings to UserDefaults.
    private func saveSettings() {
        UserDefaultsManager.shared.set(settings, for: "appSettings")
    }
    /// Loads settings from UserDefaults.
    private func loadSettings() -> Settings? {
        UserDefaultsManager.shared.get(for: "appSettings", type: Settings.self)
    }
}

struct Settings :Codable {
    var prompt: [PromptType: [RecognizerLocale : String]]
    var serverURL: String
    var audioSilentDB: String
    var selectedLocale: RecognizerLocale
    var promptType: PromptType       // Summary, Memo and subscript. Memo is a list of bulletins.
    var llmParams: [String: String]  // llm parameters
    
    enum CodingKeys: String, CodingKey {
        case prompt, serverURL, audioSilentDB, selectedLocale, promptType, llmParams
    }
    
    enum PromptType: String, CaseIterable, Codable {
        case summary = "summary"
        case checklist = "checklist"
        case subscription = "subscript"
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
    case Filipino = "phi"
    case ViệtNam = "vi"
    case แบบไทย = "th"
    
    // fr, sp,
    var id: Self { self }
    
    static let availables: Array<RecognizerLocale> = [.English, .日本語, .中文, .한국인, .Español, .Indonesia, .ViệtNam, .แบบไทย]
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
                                          serverURL: "bunny.leither.uk/secretari",
                                          audioSilentDB: "-40",
                                          selectedLocale: Utility.systemLanguage(),
                                          promptType: Settings.PromptType.summary,
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
            RecognizerLocale.ViệtNam: "Bạn là một thư ký thông minh. Trích xuất nội dung quan trọng từ văn bản sau và tạo thành một bản tóm tắt toàn diện. Chia nó thành các phần thích hợp. Định dạng đầu ra phải là văn bản thuần túy. ",
            RecognizerLocale.แบบไทย: "คุณเป็นเลขาที่ชาญฉลาด แยกเนื้อหาที่สำคัญออกจากข้อความต่อไปนี้และสรุปให้ครอบคลุม แบ่งออกเป็นส่วนๆ ตามความเหมาะสม รูปแบบผลลัพธ์ควรเป็นข้อความธรรมดา ",
        ],
        Settings.PromptType.subscription: [
            RecognizerLocale.English: "The following text is a voice recording. Organize the text, remove meaningless clichés, repeated content, etc., and divide it into appropriate paragraphs. ",
            RecognizerLocale.中文: "下述文字是一段語音錄音。整理該段文字，去除無意義的口頭禪、重複內容等，並適當分段。 ",
            RecognizerLocale.日本語: "以下のテキストは音声録音です。テキストを整理し、意味のない決まり文句や繰り返しの内容などを削除し、適切な段落に分割します。 ",
            RecognizerLocale.Español: "El siguiente texto es una grabación de voz. Organiza el texto, elimina clichés sin sentido, contenido repetido, etc. y divídelo en párrafos apropiados. ",
            RecognizerLocale.Indonesia: "Teks berikut adalah rekaman suara. Atur teks, hilangkan klise yang tidak berarti, konten yang berulang, dsb., dan bagi ke dalam paragraf yang sesuai. ",
            RecognizerLocale.한국인: "다음 텍스트는 음성 녹음입니다. 텍스트를 구성하고, 무의미한 상투적인 표현, 반복되는 내용 등을 제거한 후 적절한 문단으로 나눕니다. ",
            RecognizerLocale.ViệtNam: "Đoạn văn sau đây là bản ghi âm giọng nói. Sắp xếp văn bản, loại bỏ những câu sáo rỗng vô nghĩa, nội dung lặp lại, v.v. và chia thành các đoạn văn phù hợp. ",
            RecognizerLocale.แบบไทย: "ข้อความต่อไปนี้เป็นการบันทึกเสียง จัดระเบียบข้อความ ลบคำซ้ำที่ไม่มีความหมาย เนื้อหาที่ซ้ำกัน ฯลฯ และแบ่งออกเป็นย่อหน้าที่เหมาะสม ",
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

            """,
            RecognizerLocale.ViệtNam: """
            Bạn là một trợ lý thông minh. Trích xuất nội dung quan trọng từ văn bản thô bên dưới và tạo một bản ghi nhớ toàn diện. Định dạng đầu ra sử dụng chuỗi JSON sau, trong đó tiêu đề là nội dung mục của bản ghi nhớ.
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
            RecognizerLocale.แบบไทย: """
            คุณเป็นผู้ช่วยที่ชาญฉลาด แยกเนื้อหาที่สำคัญออกจากข้อความดิบด้านล่างและจัดทำบันทึกที่ครอบคลุม รูปแบบเอาต์พุตใช้ลำดับ JSON ต่อไปนี้ โดยที่ title คือเนื้อหารายการในบันทึกช่วยจำ
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
