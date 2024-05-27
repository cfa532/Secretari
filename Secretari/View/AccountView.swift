//
//  AccountView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/26.
//

import SwiftUI

struct AccountView: View {
    @State private var user: User = UserManager.shared.currentUser ?? User(username: "", password: "")
    @State private var passwd: String = ""
    @State private var showAlert = false
    @StateObject private var userManager = UserManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Information")) {
                    VStack {
                        HStack {Text("Username:")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("*").foregroundStyle(.red)
                            Spacer()
                        }
                        TextField(user.username.count==0 ? "< 20 characters long" : user.username, text: $user.username)
                            .foregroundColor(.secondary)
                            .background(Color.gray.opacity(0.1))
                        //                            .border(Color.gray, width: 1)
                    }
                    HStack {
                        VStack {
                            HStack {
                                Text("Password:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("*").foregroundStyle(.red)
                                Spacer()
                            }
                            TextField("", text: $user.password)
                                .foregroundColor(.secondary)
                                .background(Color.gray.opacity(0.15))
                        }
                        Spacer()
                        VStack {
                            HStack {
                                Text("again:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("*").foregroundStyle(.red)
                                Spacer()
                            }
                            TextField("", text: $passwd)
                                .foregroundColor(.secondary)
                                .background(Color.gray.opacity(0.15))
                        }
                    }
                    VStack {
                        Text("Family name:")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField(user.family_name ?? "", text: Binding<String> (
                            get: {user.family_name ?? ""}, set: { user.family_name = $0}
                        ))
                        .foregroundColor(.secondary)
                        .background(Color.gray.opacity(0.1))
                    }
                    
                    VStack {
                        Text("Given name:")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField(user.given_name ?? "", text: Binding<String> (
                            get: {user.given_name ?? ""}, set: { user.given_name = $0}
                        ))
                        .foregroundColor(.secondary)
                        .background(Color.gray.opacity(0.1))
                    }
                    
                    VStack {
                        Text("email:")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField(user.email ?? "For recovering account", text: Binding<String> (
                            get: {user.email ?? ""}, set: { user.email = $0}
                        ))
                        .foregroundColor(.secondary)
                        .background(Color.gray.opacity(0.1))
                    }
                }
                Section(header: Text("")) {
                    Button(action: {
                        // register
                        if user.username.count>0, user.password.count>0, user.password==passwd {
                            
                            // prepare currentUser for save to keychain. If it fails, restore currentUser.
                            userManager.currentUser?.username = user.username
                            userManager.currentUser?.password = user.password
                            userManager.currentUser?.family_name = user.family_name
                            userManager.currentUser?.given_name = user.given_name
                            userManager.currentUser?.email = user.email
                            
                            userManager.register(user)
                        } else {
                            print(user.username, user.password, passwd)
                            showAlert = true
                        }
                    }, label: {
                        Text("Register")
                    })
                    .alert("Alert", isPresented: $showAlert) {
                           Button("OK", role: .cancel) { }
                       } message: {
                           Text("Username and password are required. Please make sure to input the same password twice." )
                       }
                }
            }
            .onAppear(perform: {
                if user.username.count >= 20 {
                    // this is a temp account.
                    user.username = ""
                    user.password = ""
                }
                print(UserManager.shared.currentUser as Any)
            })
            .alert(isPresented: $userManager.showAlert) {
                Alert(title: userManager.alertItem?.title ?? Text("Alert"), message: userManager.alertItem?.message, dismissButton: userManager.alertItem?.dismissButton)
            }
        }
    }
}

#Preview {
    AccountView()
}
