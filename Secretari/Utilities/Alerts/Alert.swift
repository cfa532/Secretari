//
//  Alert.swift
//  Appetizers
//
//  Created by Sean Allen on 11/13/20.
//

import SwiftUI

struct AlertItem: Identifiable {
    let id = UUID()
    let title: Text
    var message: Text
    let dismissButton: Alert.Button
}


struct AlertContext {
    //MARK: - Network Alerts
    static let invalidData      = AlertItem(title: Text("Server Error"),
                                            message: Text("The data received from the server was invalid. Please contact support."),
                                            dismissButton: .default(Text("OK")))
    
    static let invalidResponse  = AlertItem(title: Text("Server Error"),
                                            message: Text("Invalid response from the server. Please try again later or contact support."),
                                            dismissButton: .default(Text("OK")))
    
    static let invalidURL       = AlertItem(title: Text("Server Error"),
                                            message: Text("There was an issue connecting to the server. If this persists, please contact support."),
                                            dismissButton: .default(Text("OK")))
    
    static let unableToComplete = AlertItem(title: Text("Server Error"),
                                            message: Text("Unable to complete your request at this time. Please check your internet connection."),
                                            dismissButton: .default(Text("OK")))
    
    
    //MARK: - Account Alerts
    static let invalidForm      = AlertItem(title: Text("Invalid Form"),
                                            message: Text("Please ensure all fields in the form have been filled out."),
                                            dismissButton: .default(Text("OK")))
    
    static let invalidEmail     = AlertItem(title: Text("Invalid Email"),
                                            message: Text("Please ensure your email is correct."),
                                            dismissButton: .default(Text("OK")))
    
    static let userSaveSuccess  = AlertItem(title: Text("Profile Saved"),
                                            message: Text("Your profile information was successfully saved."),
                                            dismissButton: .default(Text("OK")))
    
    static let invalidUserData  = AlertItem(title: Text("Profile Error"),
                                            message: Text("There was an error saving or retrieving your profile."),
                                            dismissButton: .default(Text("OK")))
    
    //MARK: - Translation Alerts
    static let emptyMemo    = AlertItem(title: Text("Memo Missing"),
                                                message: Text("No memo to translate. Please generate the Memo content first using Summarize in ... menu."),
                                                dismissButton: .default(Text("OK")))

    static let emptySummary    = AlertItem(title: Text("Summary Missing"),
                                                message: Text("No summary to translate. Please generate the Summary content first using Summarize in ... menu."),
                                                dismissButton: .default(Text("OK")))
    
    //Mark: - Invalid JSON Alerts
    static let invalidJSON  = AlertItem(title: Text("Invalid JSON"),
                                        message: Text("Invalid JSON data from AI. Try again later."),
                                        dismissButton: .default(Text("OK")))
}
