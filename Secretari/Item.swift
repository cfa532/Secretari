//
//  Item.swift
//  Secretari
//
//  Created by 超方 on 2024/4/19.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
