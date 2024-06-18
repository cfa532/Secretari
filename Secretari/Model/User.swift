//
//  User.swift
//  Secretari
//
//  Created by 超方 on 2024/5/29.
//

import Foundation

struct User :Codable, Identifiable {
    var id: String               // when temp user is created, use device identifier as id, and temp username. The device idetifier is an UUID.
    var username: String
    var password: String
    var token_count: UInt = 0     // Account balance in token amount per LLModel
    var dollar_balance: Double = 0.0    // total usage in dollar amount per LLModel
    var monthly_usage: [String: Double]?   // current month usage. month is string 1..12
    var family_name: String?
    var given_name: String?
    var email: String?

    enum CodingKeys: String, CodingKey {
        case id, username, token_count, dollar_balance, monthly_usage, password, family_name, given_name, email
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
