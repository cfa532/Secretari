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
    @State private var showAlert: Bool = false
    
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
                            SecureField(user.password, text: $user.password)
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
                            SecureField("", text: $passwd)
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
                            UserManager.shared.currentUser?.username = user.username
                            UserManager.shared.currentUser?.password = user.password
                            UserManager.shared.currentUser?.family_name = user.family_name
                            UserManager.shared.currentUser?.given_name = user.given_name
                            UserManager.shared.currentUser?.email = user.email
                            UserManager.shared.register(user)
                        } else {
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
        }
    }
}

#Preview {
    AccountView()
}
