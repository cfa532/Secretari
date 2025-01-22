//
//  Utilities.swift
//  Secretari
//
//  Created by 超方 on 2024/4/24.
//

import Foundation

struct Utility {
    /// - Parameters:
    ///   - identifier: The language identifier (e.g., "zh_CN", "en").
    /// - Returns: The localized name of the language, or the identifier if localization fails.
    static func LanguageName(_ identifier: String) -> String {  // zh_CN, lang to recognize
        let langCode = Bundle.main.preferredLocalizations.first ?? "en"    // first langauge supported by iPhone
        let locale = Locale(identifier: langCode)
        if let languageName = locale.localizedString(forLanguageCode: identifier) {
            return languageName
        }
        return locale.identifier
    }
    
    /// - Returns: The system's language as a `RecognizerLocale`, or `.English` if the language is not recognized.
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
    /// Parses a string containing AI output to extract a JSON array string.
    ///
    /// This function uses a regular expression to find content within square brackets `[]` and returns it as a JSON string.
    /// It replaces new line characters with spaces before applying the regex. Each Json element is {id, title, checked}
    ///
    /// - Parameter aiJson: The string containing AI output.
    /// - Returns: A JSON string containing the extracted array, or "[Invalid JSON data]" if no valid array is found.
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
    
    /// Converts a dictionary with String keys to a dictionary with `LLMModel` enum keys.
    ///
    /// - Parameter original: The original dictionary with String keys.
    /// - Returns: A new dictionary with `LLMModel` enum keys. Unrecognized keys are ignored and a warning is printed.
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
    
    /// Updates a `User` object with data from a dictionary.
    ///
    /// - Parameters:
    ///   - dict: The dictionary containing user data.
    ///   - user: The `User` object to update.
    /// - Returns: The updated `User` object.
    static func updateUserFromServerDict<T>(from dict: [String: T], user: User) -> User {
        var user = user
        if let id = dict["id"] as? String {
            user.id = id
        }
        if let family_name = dict["family_name"] as? String {
            user.family_name = family_name
        }
        if let given_name = dict["given_name"] as? String {
            user.given_name = given_name
        }
        if let email = dict["email"] as? String {
            user.email = email
        }
        if let tokenCountData = dict["token_count"] as? UInt {
            user.token_count = tokenCountData
        }
        if let currentUsageData = dict["monthly_usage"] as? [String: Double] {
            user.monthly_usage = currentUsageData
        }
        // manage dollar balance by Server
        if let tokenUsageData = dict["dollar_balance"] as? Double {
            user.dollar_balance = tokenUsageData
        }
        return user
    }
}
