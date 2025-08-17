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
    //MARK: - Success
    static let rechargeSuccess  = AlertItem(title: Text(LocalizedStringKey("Success")),
                                            message: Text(LocalizedStringKey("Recharge success. Please check your account balance.")),
                                            dismissButton: .default(Text(LocalizedStringKey("OK"))))
    
    //MARK: - Network Alerts
    static let invalidData      = AlertItem(title: Text(LocalizedStringKey("Server Error")),
                                            message: Text(LocalizedStringKey("The data received from the server was invalid. Please contact support.")),
                                            dismissButton: .default(Text(LocalizedStringKey("OK"))))
    
    static let invalidResponse  = AlertItem(title: Text(LocalizedStringKey("Server Error")),
                                            message: Text(LocalizedStringKey("Invalid response from the server. Please try again later or contact support.")),
                                            dismissButton: .default(Text(LocalizedStringKey("OK"))))
    
    static let invalidURL       = AlertItem(title: Text(LocalizedStringKey("Server Error")),
                                            message: Text(LocalizedStringKey("There was an issue connecting to the server. If this persists, please contact support.")),
                                            dismissButton: .default(Text(LocalizedStringKey("OK"))))
    
    static let unableToComplete = AlertItem(title: Text(LocalizedStringKey("Server Error")),
                                            message: Text(LocalizedStringKey("Unable to complete your request at this time. Please check your internet connection.")),
                                            dismissButton: .default(Text(LocalizedStringKey("OK"))))
    
    
    //MARK: - Account Alerts
    static let invalidForm      = AlertItem(title: Text(LocalizedStringKey("Invalid Form")),
                                            message: Text(LocalizedStringKey("Please ensure all fields in the form have been filled out.")),
                                            dismissButton: .default(Text(LocalizedStringKey("OK"))))
    
    static let invalidEmail     = AlertItem(title: Text(LocalizedStringKey("Invalid Email")),
                                            message: Text(LocalizedStringKey("Please ensure your email is correct.")),
                                            dismissButton: .default(Text(LocalizedStringKey("OK"))))
    
    static let userSaveSuccess  = AlertItem(title: Text(LocalizedStringKey("Profile Saved")),
                                            message: Text(LocalizedStringKey("Your profile information was successfully saved.")),
                                            dismissButton: .default(Text(LocalizedStringKey("OK"))))
    
    static let invalidUserData  = AlertItem(title: Text(LocalizedStringKey("Profile Error")),
                                            message: Text(LocalizedStringKey("There was an error saving or retrieving your profile.")),
                                            dismissButton: .default(Text(LocalizedStringKey("OK"))))
    
    //MARK: - Translation Alerts
    static let emptyMemo    = AlertItem(title: Text(LocalizedStringKey("Memo Missing")),
                                                message: Text(LocalizedStringKey("No memo to translate. Please generate the Memo content first using Summarize in ... menu.")),
                                                dismissButton: .default(Text(LocalizedStringKey("OK"))))

    static let emptySummary    = AlertItem(title: Text(LocalizedStringKey("Summary Missing")),
                                                message: Text(LocalizedStringKey("No summary to translate. Please generate the Summary content first using Summarize in ... menu.")),
                                                dismissButton: .default(Text(LocalizedStringKey("OK"))))
    
    //Mark: - Invalid JSON Alerts
    static let invalidJSON  = AlertItem(title: Text(LocalizedStringKey("Invalid JSON")),
                                        message: Text(LocalizedStringKey("Invalid JSON data from AI. Try again later.")),
                                        dismissButton: .default(Text(LocalizedStringKey("OK"))))
}
