//
//  ErrorWrapper.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/29.
//

import Foundation

struct ErrorWrapper: Identifiable {
    let id: UUID
    let error: Error
    let guidance: String
    
    init(id: UUID=UUID(), error: Error, guidance: String) {
        self.id = id
        self.error = error
        self.guidance = guidance
    }
    
    enum MyError: Error {
        case someError
        case anotherError(reason: String)
    }

    static let emptyError = ErrorWrapper(error: MyError.someError, guidance: "Nothing wrong")
}
