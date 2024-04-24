//
//  Utilities.swift
//  Secretari
//
//  Created by 超方 on 2024/4/24.
//

import Foundation

struct Localized {
    static func LanguageName(_ identifier: String) -> String {  // zh_CN, lang to recognize
        let langCode = Bundle.main.preferredLocalizations[0]    // first langauge supported by iPhone
        print("langCode=", langCode, identifier)
        let locale = Locale(identifier: langCode)
        if let languageName = locale.localizedString(forLanguageCode: identifier) {
            print("Localized name=", languageName)
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
}
