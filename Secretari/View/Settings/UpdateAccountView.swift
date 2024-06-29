//
//  UpdateAccountView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/27.
//

import SwiftUI

struct UpdateAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var userManager: UserManager
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var email: String = ""
    @State private var fname: String = ""
    @State private var gname: String = ""
    @State private var passwd: String = ""
    @State private var id: String = ""

    @State private var showAlert = false
    @State private var submitted = false

//    init(userManager: UserManager) {
//        self.userManager = userManager
//        self.user = userManager.currentUser!
//    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Information")) {
                    InputView(text: $username, title: "Username", placeHolder: "", isSecureField: false, required: true)
                        .padding(.top, 10)
                        .textInputAutocapitalization(.never)
                    HStack {
                        InputView(text: $password, title: "Password", placeHolder: "", isSecureField: true, required: true)
                        InputView(text: $passwd, title: "Confirm", placeHolder: "", isSecureField: true, required: true)
                    }
                    InputView(text: $fname, title: "Family name", placeHolder: "")
                    InputView(text: $gname, title: "Given name", placeHolder: "")
                    InputView(text: $email, title: "Email", placeHolder: "")
                    .textInputAutocapitalization(.never)
                }
                .onAppear(perform: {
                    if let user = userManager.currentUser {
                        username = user.username
                        email = user.email ?? ""
                        fname = user.family_name ?? ""
                        gname = user.given_name ?? ""
                        id = user.id
                    }
                })

                Section(header: Text("")) {
                    Button(action: {
                        // register
                        if password == passwd {
                            Task {
                                self.submitted = true
                                await userManager.updateUser(User(id: id, username: username, password: password, family_name: fname, given_name: gname, email: email))
                                presentationMode.wrappedValue.dismiss()
                            }
                        } else {
                            print(username, password, passwd)
                            showAlert = true
                        }
                    }, label: {
                        ZStack {
                            HStack {
                                Text("Update")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .foregroundStyle(.white)
                            .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                            
                            if self.submitted {
                                ProgressView()
                                    .controlSize(.large)
                            }
                        }
                    })
                    .background(Color(.systemBlue).opacity(0.8))
                    .cornerRadius(10)
                    .alert("Alert", isPresented: $showAlert) {
                           Button("OK", role: .cancel) { }
                       } message: {
                           Text("Please confirm the password." )
                       }
                }
            }
        }
    }
}
#Preview {
    UpdateAccountView()
        .environmentObject(UserManager.shared)
}
