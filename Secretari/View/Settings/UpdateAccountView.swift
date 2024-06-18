//
//  UpdateAccountView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/27.
//

import SwiftUI

struct UpdateAccountView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var userManager: UserManager
    @State private var user: User
    @State private var passwd: String = ""
    @State private var showAlert = false
    @State private var submitted = false

    init(userManager: UserManager) {
        self.userManager = userManager
        self.user = userManager.currentUser!
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Information")) {

                    InputView(text: $user.username, title: "Username", placeHolder: user.username, isSecureField: false, required: true)
                        .padding(.top, 40)
                        .textInputAutocapitalization(.never)
                        .disabled(true)
                    
                    HStack {
                        InputView(text: $user.password, title: "Password", placeHolder: "", isSecureField: true, required: true)
                        InputView(text: $passwd, title: "Confirm", placeHolder: "", isSecureField: true, required: true)
                    }
                    
                    InputView(text: Binding<String> (get: {user.family_name ?? ""}, set: {user.family_name=$0}), title: "Family name", placeHolder: user.family_name ?? "")
                    

                    InputView(text: Binding<String> (get: {user.given_name ?? ""}, set: { user.given_name = $0}), title: "Given name", placeHolder: user.given_name ?? "")

                    InputView(text: Binding<String> (get: {user.email ?? ""}, set: { user.email = $0}), title: "Email", placeHolder: user.email ?? "")
                    .textInputAutocapitalization(.never)
                }

                Section(header: Text("")) {
                    Button(action: {
                        // register
                        if user.password==passwd {
                            Task {
                                self.submitted = true
                                await userManager.updateUser(user)
                                presentationMode.wrappedValue.dismiss()
                            }
                        } else {
                            print(user.username, user.password, passwd)
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
            .alert(isPresented: $userManager.showAlert) {
                Alert(title: userManager.alertItem?.title ?? Text("Alert"),
                      message: userManager.alertItem?.message,
                      dismissButton: userManager.alertItem?.dismissButton)
            }
        }
    }
}
#Preview {
    UpdateAccountView(userManager: UserManager.shared)
}
