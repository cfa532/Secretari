//
//  User.swift
//  Secretari
//
//  Created by 超方 on 2024/5/29.
//

import Foundation

struct User :Codable {
    var username: String
    var password: String
    var mid: String?
    var token_count: [LLMModel: UInt]?     // gotten from server, kept locally
    var token_usage: [LLMModel: Double]?
    var current_usage: [LLMModel: Double]?   // current month usage
    var subscription: Bool = false          // Flag indicating active subscription
    var family_name: String?
    var given_name: String?
    var email: String?
    var template: [LLM: [String: String]]?
    
    enum CodingKeys: String, CodingKey {
        case username, mid, token_count, token_usage, current_usage, subscription, password, family_name, given_name, email, template
    }
    
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: given_name ?? "John" + " " + (family_name ?? "Smith")) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        return ""
    }
    
    var diaplayUsername: String? {
        if username.count > 20 {
            return nil
        }
        return username
    }
}
