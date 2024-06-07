//
//  Utilities.swift
//  Secretari
//
//  Created by 超方 on 2024/4/24.
//

import Foundation

struct Utility {
    static func LanguageName(_ identifier: String) -> String {  // zh_CN, lang to recognize
        let langCode = Bundle.main.preferredLocalizations.first ?? "en"    // first langauge supported by iPhone
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
    }
    static func printDict(obj: Dictionary<String, Any>) {
        print(obj.description)
        for(key, value) in obj {
            print("\(key) = \(value)")
        }
    }
    
    static func getAIJson(aiJson: String) throws ->String {
        let regex = try NSRegularExpression(pattern: "\\[(.*?)\\]", options: [])
        let str = aiJson.replacingOccurrences(of: "\n", with: " ")      // regex has problem with new line char.
        let nsString = str as NSString
        let results = regex.matches(in: str, options: [], range: NSRange(location: 0, length: nsString.length))
        let r = results.map{ nsString.substring(with: $0.range(at: 1)) }
        if let str = r.first {
            return "[" + str + "]"
        }
        return "[Invalid JSON data]"
    }
    
    // Utility function to convert dictionary keys from String to LLMModel
    static func convertDictionaryKeys<T>(from original: [String: T]) -> [LLMModel: T] {
        var convertedDict = [LLMModel: T]()
        for (key, value) in original {
            if let enumKey = LLMModel(rawValue: key) {
                convertedDict[enumKey] = value
            } else {
                print("Warning: Unrecognized key \(key). It will be ignored.")
            }
        }
        return convertedDict
    }

    static func updateUserFromServerDict<T>(from dict: [String: T], user: User) -> User {
        var user = user
        if let tokenCountData = dict["token_count"] as? UInt {
            user.token_count = tokenCountData
        }
        if let tokenUsageData = dict["dollar_balance"] as? Double {
            user.dollar_balance = tokenUsageData
        }
        if let currentUsageData = dict["monthly_usage"] as? [String: Double] {
            user.monthly_usage = currentUsageData
        }
        // verify subscription status on device
//        if let subscription = dict["subscription"] as? Bool {
//            user.subscription = subscription
//        }
        // save User information to keychain
        if let mid = dict["mid"] as? String {
            user.mid = mid
        }
        return user
    }
}
