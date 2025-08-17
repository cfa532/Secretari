//
//  AccountView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/27.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var entitlementManager: EntitlementManager

    var body: some View {
        switch userManager.loginStatus {
        case .signedIn:
            // account details
            AccountDetailView(isSubscriber: entitlementManager.hasPro)
        case .signedOut:
            // login page
            LoginView()
        case .unregistered:
            // register
            RegistrationView()
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(UserManager.shared)
        .environmentObject(EntitlementManager())
}

struct AccountDetailView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var showAlert = false
    @State private var showDelete = false
    @State var isSubscriber: Bool

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
                            
                            Text(userManager.currentUser?.email ?? "email@account")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        })
                    }
                }
                Section("General") {
                    HStack {
                        let title = Text(LocalizedStringKey("Username"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        SettingsRowView(title: title, tintColor: .secondary)
                        Spacer()
                        if let username = userManager.currentUser?.diaplayUsername {
                            Text(username)
                        } else {
                            Button(LocalizedStringKey("Signup now")) {
                                userManager.loginStatus = .unregistered
                            }
                        }
                    }
                    HStack {
                        Text(LocalizedStringKey("Token usage:"))
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                        Spacer()
                        if let count = userManager.currentUser?.token_count {
                            Text(formatterInt().string(from: NSNumber(value: count))!)
                        }
                    }
                    if isSubscriber {
                        HStack {
                            Text(LocalizedStringKey("Subscription status"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if isSubscriber {
                                Text("✔︎")
                                    .foregroundStyle(.green)
                                    .font(.system(size: 25))
                            } else {
                                Text("✖︎")
                                    .foregroundStyle(.red)
                                    .font(.system(size: 25))
                            }
                        }
                    } else {
                        if let balance = userManager.currentUser?.dollar_balance {
                            HStack {
                                Text(LocalizedStringKey("Account balance in USD:"))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(formatterInt().string(from: NSNumber(value: estimateTokens(balance)))!)
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
                    if let user = userManager.currentUser, user.username.count > 20 {
                        // this is a temp account, created for user by system
                        Button {
                            userManager.loginStatus = .signedOut
                        } label: {
                            HStack(spacing: 5, content: {
                                Text(LocalizedStringKey("Have an account?"))
                                Text(LocalizedStringKey("Sign in"))
                                    .fontWeight(.bold)
                                    .opacity(0.9)
                                Image(systemName: "arrow.right.circle.fill")
                            })
                            .font(.system(size: 16))
                        }
                    } else {
                        // a real account registered by user
                        Button(action: {
                            self.showAlert = true
                        }, label: {
                            SettingsRowView(imageName: "arrow.left.circle.fill", title:Text(LocalizedStringKey("Sign out")), tintColor: .accentColor)
                        })
                        // Do NOT show update option to temp user
                        NavigationLink(destination: UpdateAccountView(), label: {
                            SettingsRowView(imageName: "wand.and.stars", title:Text(LocalizedStringKey("Update account")), tintColor: .accentColor)
                        })
                        Button(action: {
                            self.showDelete = true
                        }, label: {
                            SettingsRowView(imageName: "trash", title:Text(LocalizedStringKey("Delete account")), tintColor: .accentColor)
                        })
                    }
                }
                .alert(LocalizedStringKey("Sign out"), isPresented: $showAlert) {
                    Button(LocalizedStringKey("OK"), action: {userManager.userToken = nil})
                    Button(LocalizedStringKey("Cancel"), role: .cancel, action: { print("cancelled")})
                } message: {
                    Text(LocalizedStringKey("Are you sure to logout?"))
                }
                .alert(LocalizedStringKey("Delete account"), isPresented: $showDelete) {
                    Button(LocalizedStringKey("OK"), action: {
                        Task {
                            await userManager.deleteAccount()}
                    })
                    Button(LocalizedStringKey("Cancel"), role: .cancel, action: { print("cancelled")})
                } message: {
                    Text(LocalizedStringKey("Are you sure to delete account?"))
                }
            }
            // display version at bottom
            Spacer()
            Text(appVersion())
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }
    
    private let formatterInt = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal // Use the decimal style
        formatter.groupingSeparator = "," // Explicitly set the grouping separator to comma
        formatter.usesGroupingSeparator = true // Enable the use of the grouping separator
        return formatter
    }
    func estimateTokens(_ dollar: Double) -> Int {
        return Int(dollar*4*1000000/30)
    }
    func fullName() -> String {
        return (userManager.currentUser?.family_name ?? "No") + " " + (userManager.currentUser?.given_name ?? "one")
    }
    
    func appVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "version@" + version
        }
        return " "
    }
}

#Preview {
    AccountDetailView(isSubscriber: false)
        .environmentObject(UserManager.shared)
}
