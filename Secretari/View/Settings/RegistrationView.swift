//
//  AccountView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/26.
//

import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var user: User
    @State private var passwd: String = ""
    @State private var showAlert = false
    @State private var submitted = false
    
    init() {
        self.user = UserManager.shared.currentUser!
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Information")) {

                    InputView(text: $user.username, title: "Username", placeHolder: "", isSecureField: false, required: true)
                        .padding(.top, 10)
                        .textInputAutocapitalization(.never)

                    
                    HStack {
                        InputView(text: $user.password, title: "Password", placeHolder: "", isSecureField: true, required: true)
                        InputView(text: $passwd, title: "Confirm", placeHolder: "", isSecureField: true, required: true)
                    }
                    
                    InputView(text: Binding<String> (get: {""}, set: {user.family_name=$0}), title: "Family name", placeHolder: "")
                    

                    InputView(text: Binding<String> (get: {user.given_name ?? ""}, set: { user.given_name = $0}), title: "Given name", placeHolder: "")

                    InputView(text: Binding<String> (get: {user.email ?? ""}, set: { user.email = $0}), title: "Email", placeHolder: "")
                    .textInputAutocapitalization(.never)
                }

                Section(header: Text("")) {
                    Button(action: {
                        // register
                        if 1...20 ~= user.username.count, user.password.count>0, user.password==passwd {
                            self.submitted = true
                            userManager.register(user)
                        } else {
                            print(user.username, user.password, passwd)
                            showAlert = true
                        }
                    }, label: {
                        ZStack {
                            HStack {
                                Text("SIGN UP")
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
                           Text("Username is required and less than 20 characters long. Please confirm the password." )
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
                Alert(title: userManager.alertItem?.title ?? Text("Alert"),
                      message: userManager.alertItem?.message,
                      dismissButton: userManager.alertItem?.dismissButton)
            }
            Button {
                userManager.loginStatus = .signedOut
            } label: {
                HStack(spacing: 5, content: {
                    Text("Have an account?")
                    Text("Sign in")
                        .fontWeight(.bold)
                        .opacity(0.9)
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
