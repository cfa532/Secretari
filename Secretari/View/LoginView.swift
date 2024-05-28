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
                InputView(text: $username, title: "Username", placeHolder: "username", isSecureField: false, required: required)
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
                    UserManager.shared.login(username: username, password: password)
                } else {
                    self.required = true
                }
            } label: {
                HStack {
                    Text("SIGN IN")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(.white)
                .frame(width: UIScreen.main.bounds.width - 32, height: 48)
            }
            .background(Color(.systemBlue).opacity(0.8))
            .cornerRadius(10)
            Spacer()
            
            if let count=UserManager.shared.currentUser?.username.count, count > 20 {
                Button {
                    UserManager.shared.loginStatus = .unregistered
                } label: {
                    HStack(spacing: 3, content: {
                        Text("Don't have an account?")
                        Text("Sign up")
                            .fontWeight(.bold)
                            .opacity(0.9)
                    })
                    .font(.system(size: 16))
                }
            }
        }
    }
    
    func login() {
        // Here you would typically handle the login logic, possibly verifying credentials with a server.
        print("Login attempt for \(username) with password \(password)")
    }
}

#Preview {
    LoginView()
}
