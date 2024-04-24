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
            print("Localized lang=", languageName)
            return languageName
        }
        return locale.identifier
    }
    
    // language in iPhone settings
    static func systemLanguage() -> RecognizerLocals {
        switch NSLocale.current.language.languageCode?.identifier {
        case "zh":
            return RecognizerLocals.Chinese
        case "ja":
            return RecognizerLocals.Japanese
        default:
            return RecognizerLocals.English
        }
    }
}
