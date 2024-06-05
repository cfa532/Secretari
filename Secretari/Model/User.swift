//
//  User.swift
//  Secretari
//
//  Created by 超方 on 2024/5/29.
//

import Foundation

struct User :Codable, Identifiable {
    var id: String { username }
    var username: String
    var password: String
    var mid: String?
    var token_count: [LLMModel: UInt]?     // Account balance in token amount per LLModel
    var dollar_balance: [LLMModel: Double]?    // total usage in dollar amount per LLModel
    var monthly_usage: [String: Double]?   // current month usage. month is string 1..12
    var subscription: Bool = false          // Flag indicating active subscription
    var family_name: String?
    var given_name: String?
    var email: String?
    var template: [LLM: [String: String]]?      // LLM parameters for eahc model.
    var purchaseHistory: [String: String]?         // [productID, purchase date, amount} or {productID, start date, end date, monthly/yearly, price}
    
    enum CodingKeys: String, CodingKey {
        case username, mid, token_count, dollar_balance, monthly_usage, subscription, password, family_name, given_name, email, template, purchaseHistory
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
        if username.count > 20 {    // a system create string as temp name. Do not display it.
            return nil
        }
        return username
    }
}
