//
//  AccountView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/26.
//

import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var email: String = ""
    @State private var fname: String = ""
    @State private var gname: String = ""
    @State private var passwd: String = ""
    @State private var id: String = ""
    @State private var showAlert = false
    @State private var submitted = false
    
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedStringKey("Information"))) {
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
                    if let uid = userManager.currentUser?.id {
                        id = uid
                    }
                })

                Section(header: Text("")) {
                    Button(action: {
                        // register
                        if 1...20 ~= username.count, password.count>0, password==passwd {
                            self.submitted = true
                            let user = User(id: id, username: username, password: password, family_name: fname, given_name: gname, email: email)
                            Task {
                                if !(await userManager.register(user)) {
                                    self.submitted = false
                                    self.errorMessage = NSLocalizedString("Username is taken", comment: "")
                                    self.showAlert = true
                                }
                            }
                        } else {
                            print(username, password, passwd)
                            self.errorMessage = NSLocalizedString("Username is required and less than 20 characters long. Please confirm the password.", comment: "")
                            showAlert = true
                        }
                    }, label: {
                        ZStack {
                            HStack {
                                Text(LocalizedStringKey("SIGN UP"))
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
                           Text(LocalizedStringKey(self.errorMessage))
                       }
                }
            }
//            .alert(isPresented: $userManager.showAlert) {
//                Alert(title: userManager.alertItem?.title ?? Text("Alert"),
//                      message: userManager.alertItem?.message,
//                      dismissButton: userManager.alertItem?.dismissButton)
//            }

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
        }
    }
}

#Preview {
    RegistrationView()
        .environmentObject(UserManager.shared)
}
