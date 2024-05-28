//
//  AccountView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/27.
//

import SwiftUI

struct AccountView: View {
    @StateObject var userManager = UserManager.shared
    
    var body: some View {
        switch userManager.loginStatus {
        case .signedIn:
            // account details
            AccountDetailView()
        case .signedOut:
            // login page
            LoginView()
//                .alert(isPresented: $userManager.showAlert) {
//                    Alert(title: userManager.alertItem?.title ?? Text("Alert"), message: userManager.alertItem?.message, dismissButton: userManager.alertItem?.dismissButton)
//                }
                .alert("Login error", isPresented: $userManager.showAlert, presenting: userManager.alertItem) { _ in
                    Button("OK", role: .cancel, action: {print("OK")})
                } message: { alertItem in
                    alertItem.message
                }

        case .unregistered:
            // register
            RegistrationView()
        }
    }
}

struct AccountDetailView: View {
    @State private var showAlert = false
    @State private var user = UserManager.shared.currentUser
    @StateObject var userManager = UserManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                            .background(Color(.systemGray))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4, content: {
                            Text(String(describing: fullName()))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.top, 4)
                            
                            Text(user?.email ?? "email@account")
                                .font(.footnote)
                        })
                    }
                }
                Section("General") {
                    VStack(alignment: .leading) {
                        Text("Username:")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                        Text(user?.username ?? " ")
                    }
                    VStack(alignment: .leading) {
                        Text("Account blance: ")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                        if let g3 = user?.token_count, let g3c=g3[LLMModel.GPT_3] {
                            Text("GPT-3 " + String(describing: g3c))
                        }
                        if let g4 = user?.token_count, let g4c=g4[LLMModel.GPT_4_Turbo] {
                            Text("GPT-4-Turbo " + String(describing: g4c))
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Usage of the month:")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                        if let u3 = user?.current_usage, let u3c=u3[LLMModel.GPT_3] {
                            Text("GPT-3 " + String(describing: u3c))
                        }
                        if let u4 = user?.current_usage, let u4c=u4[LLMModel.GPT_4_Turbo] {
                            Text("GPT-4-Turbo " + String(describing: u4c))
                        }
                    }
                }
                Section("Account") {
                    Button(action: {
                        self.showAlert = true
                    }, label: {
                        Text("Sign out")
                    })
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Confirm Logout"),
                        message: Text("Are you sure you want to logout?"),
                        primaryButton: .destructive(Text("Logout")) {
                            print("User logged out")
                            userManager.userToken = nil
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }
        
    func fullName() -> String {
        return (user?.family_name ?? "Smith") + ", " + (user?.given_name ?? "John")
    }
}

#Preview {
    AccountView()
}
