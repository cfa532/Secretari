//
//  LoginView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/27.
//

import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var required = false
    @State private var submitted = false
    @EnvironmentObject var userManager: UserManager
    
    @State private var alertMessage: String?
    @State private var showAlert = false
    
    var body: some View {
        NavigationStack {
            Spacer()
            Image("bunny")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 120)
                .padding(.bottom, 50)
            //                .padding(.top, 50)
            VStack {
                InputView(text: $username, title: "Username", placeHolder: userManager.currentUser?.diaplayUsername ?? "", isSecureField: false, required: required)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                InputView(text: $password, title: "Password", placeHolder: "******", isSecureField: true, required: required)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal, 30)
            .padding(.top, 12)
            
            Button {
                if username.count>0, password.count>0 {
                    self.required = false
                    self.submitted = true
                    Websocket.shared.fetchToken(username: username, password: password) { dict, statusCode in
                        guard let dict = dict, let code=statusCode, code < .failure  else {
                            print("Failed to login.", dict as Any)
                            if let dict = dict as? [String: String] {
                                self.alertMessage = dict["detail"]  // {detail: message} received from FastAPI server
                            }
                            self.submitted = false
                            self.showAlert = true
                            return
                        }
                        // update account with token usage data from WS server
                        Task { @MainActor in
                            print("Reply to login: ", dict)
                            if let user=dict["user"] as? [String: Any], let token=dict["token"] as? [String: String] {
                                userManager.currentUser = Utility.updateUserFromServerDict(from: user, user: userManager.currentUser!)
                                userManager.currentUser?.username = username
                                userManager.currentUser?.password = ""
                                userManager.persistCurrentUser()
                                userManager.userToken = token["access_token"]
                            }
                        }
                    }
                    
                } else {
                    self.required = true        // indicate username is required field.
                }
            } label: {
                ZStack {
                    HStack {
                        Text("SIGN IN")
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
            }
            .background(Color(.systemBlue).opacity(0.8))
            .cornerRadius(10)
            Spacer()
            
//            if let count=userManager.currentUser?.username.count, count > 20 {
                Button {
                    userManager.loginStatus = .unregistered
                } label: {
                    HStack(spacing: 3, content: {
                        Text("Don't have an account?")
                        Text("Sign up")
                            .fontWeight(.bold)
                            .opacity(0.9)
                    })
                    .font(.system(size: 16))
                }
//            }
        }
        .alert("Login error", isPresented: $showAlert, presenting: alertMessage) { _ in
        } message: { alert in
            Text(LocalizedStringKey(alert))
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(UserManager.shared)
}
