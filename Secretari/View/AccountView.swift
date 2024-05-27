//
//  AccountView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/27.
//

import SwiftUI

struct AccountView: View {
    @StateObject var userManager = UserManager.shared
    private var tokenManager = TokenManager.shared

    var body: some View {
        NavigationStack {
            switch userManager.loginStatus {
            case .signedIn:
                // account details
                AccountView()
            case .signedOut:
                // login page
                LoginView()
            case .unregistered:
                // register
                RegistrationView()
            }
        }
        .onAppear(perform: {
            if let len=userManager.currentUser?.username.count, len>20 {
                userManager.loginStatus = .unregistered
            } else {
                // check secure token
                userManager.userToken = tokenManager.loadToken()
                if userManager.userToken != nil {
                    userManager.loginStatus = .signedIn
                } else {
                    userManager.loginStatus = .signedOut
                }
            }
        })
    }
}


#Preview {
    AccountView()
}
