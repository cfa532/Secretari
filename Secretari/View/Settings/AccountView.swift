//
//  AccountView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/27.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var userManager: UserManager

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
            RegistrationView(userManager: userManager)
        }
    }
}

struct AccountDetailView: View {
    @State private var showAlert = false
    @State private var user = UserManager.shared.currentUser
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var entitlementManager: EntitlementManager

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
                                .font(.headline)
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
                        let title = Text("Username")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        SettingsRowView(title: title, tintColor: .secondary)
                        Spacer()
                        Text(user?.diaplayUsername ?? "signup now")
                    }
                    HStack {
                        let title = Text("Version").font(.subheadline).foregroundStyle(.secondary)
                        SettingsRowView(imageName: nil, title: title, tintColor: .secondary)
                        Spacer()
                        Text("1.0.0")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("Token usage:")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                        Spacer()
                        if let count = user?.token_count {
                            Text(String(count))
                        }
                    }
                    if !entitlementManager.hasPro {
                        if let balance = user?.dollar_balance {
                            HStack {
                                Text("Account balance in USD:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formatterUSD().string(from: NSNumber(value: balance))!)
                            }
                        }

//                        let currentDate = Date()
//                        let calendar = Calendar.current
//                        let currentMonth = String(calendar.component(.month, from: currentDate))
//                        if let u3 = user?.monthly_usage, let u3c=u3[currentMonth] {
//                            HStack {
//                                Text("Cost of the month in USD:")
//                                    .font(.subheadline)
//                                    .foregroundStyle(.secondary)
//                                Spacer()
//                                Text(formatterUSD().string(from: NSNumber(value: u3c))!)
//                            }
//                        }
                    }
                }
                Section(" ") {
                    Button(action: {
                        self.showAlert = true
                    }, label: {
                        SettingsRowView(imageName: "arrow.left.circle.fill", title:Text("Sign out"), tintColor: .accentColor)
                    })
                    if let count=user?.username.count, count <= 20 {
                        // Do NOT show update option to temp user
                        NavigationLink(destination: UpdateAccountView(userManager: userManager), label: {
                            SettingsRowView(imageName: "wand.and.stars", title:Text("Update account"), tintColor: .accentColor)
                        })
                    }
                }
                .alert("Sign out", isPresented: $showAlert) {
                    Button("OK", action: {userManager.userToken = nil})
                    Button("Cancel", role: .cancel, action: { print("cancelled")})
                } message: {
                    Text("Are you sure to logout?")
                }
                .onAppear(perform: {
                    user = UserManager.shared.currentUser
                })

            }
        }
    }
        
    func fullName() -> String {
        return (user?.family_name ?? "No") + " " + (user?.given_name ?? "one")
    }
}

#Preview {
    AccountView()
        .environment(UserManager.shared)
}
