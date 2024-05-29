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
    
    private let formatterUSD = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // Sets the currency symbol to USD
        formatter.currencySymbol = "$" // Explicitly sets the currency symbol to $
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
    private let formatterInt = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal // Use the decimal style
        formatter.groupingSeparator = "," // Explicitly set the grouping separator to comma
        formatter.usesGroupingSeparator = true // Enable the use of the grouping separator
        return formatter
    }
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
                                .foregroundStyle(.secondary)
                        })
                    }
                }
                Section("General") {
                    HStack {
                        let title = Text("Username").font(.subheadline).foregroundStyle(.secondary)
                        SettingsRowView(title: title, tintColor: .secondary)
                        Spacer()
                        Text(user?.username ?? " ")
                    }
                    HStack {
                        let title = Text("Version").font(.subheadline).foregroundStyle(.secondary)
                        SettingsRowView(imageName: nil, title: title, tintColor: .secondary)
                        Spacer()
                        Text("v1.0.0")
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Account blance in token:")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                        if let g3 = user?.token_count, let g3c=g3[LLMModel.GPT_3] {
                            HStack {
                                Text("GPT-3:")
                                    .font(.subheadline)
                                Spacer()
                                Text(formatterInt().string(from: NSNumber(value: g3c))!)
                            }
                        }
                        if let g4 = user?.token_count, let g4c=g4[LLMModel.GPT_4_Turbo] {
                            HStack {
                                Text("GPT-4-Turbo:")
                                    .font(.subheadline)
                                Spacer()
                                Text(formatterInt().string(from: NSNumber(value: g4c))!)
                            }
                       }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Usage of the month in USD:")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                        if let u3 = user?.current_usage, let u3c=u3[LLMModel.GPT_3] {
                            HStack {
                                Text("GPT-3:")
                                    .font(.subheadline)
                                Spacer()
                                Text(formatterUSD().string(from: NSNumber(value: u3c))!)
                            }
                        }
                        if let u4 = user?.current_usage, let u4c=u4[LLMModel.GPT_4_Turbo] {
                            HStack {
                                Text("GPT-4-Turbo:")
                                    .font(.subheadline)
                                Spacer()
                                Text(formatterUSD().string(from: NSNumber(value: u4c))!)
                            }
                        }
                    }
                }
                Section("Account") {
                    Button(action: {
                        self.showAlert = true
                    }, label: {
                        HStack {
                            SettingsRowView(imageName: "arrow.left.circle.fill", title:Text("Sign out"), tintColor: .accentColor)
                        }
                    })
                }
                .alert("Sign out", isPresented: $showAlert) {
                    Button("OK", action: {userManager.userToken = nil})
                    Button("Cancel", role: .cancel, action: { print("cancelled")})
                } message: {
                    Text("Are you sure to logout?")
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
