//
//  Utilities.swift
//  Secretari
//
//  Created by 超方 on 2024/4/24.
//

import Foundation

struct Utility {
    static func LanguageName(_ identifier: String) -> String {  // zh_CN, lang to recognize
        let langCode = Bundle.main.preferredLocalizations[0]    // first langauge supported by iPhone
//        print("langCode=", langCode, identifier)
        let locale = Locale(identifier: langCode)
        if let languageName = locale.localizedString(forLanguageCode: identifier) {
//            print("Localized name=", languageName)
            return languageName
        }
        return locale.identifier
    }
    
    // language in iPhone settings
    static func systemLanguage() -> RecognizerLocale {
        if let locale = RecognizerLocale(rawValue: String(NSLocale.current.identifier.prefix(2))) { // get 2-letter language code, cn, en, ja...
            return locale
        } else {
            return RecognizerLocale.English
        }
//        switch NSLocale.current.language.languageCode?.identifier {
//        case "zh":
//            return RecognizerLocale.Chinese
//        case "ja":
//            return RecognizerLocale.Japanese
//        default:
//            return RecognizerLocale.English
//        }
    }
    
    static func getAIJson(aiJson: String) throws ->String {
        let regex = try NSRegularExpression(pattern: "\\[(.*?)\\]", options: [])
        let str = aiJson.replacingOccurrences(of: "\n", with: " ")      // regex has problem with new line char.
        let nsString = str as NSString
        let results = regex.matches(in: str, options: [], range: NSRange(location: 0, length: nsString.length))
        let r = results.map{ nsString.substring(with: $0.range(at: 1)) }
        return "[" + r[0] + "]"
    }
}
