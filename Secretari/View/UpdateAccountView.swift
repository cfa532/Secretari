//
//  UpdateAccountView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/27.
//

import SwiftUI

struct UpdateAccountView: View {
    @ObservedObject var user: UserManager = UserManager.shared
    @State private var familyName: String = ""
    @State private var givenName: String = ""
    @State private var email: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Family Name", text: $familyName)
                    TextField("Given Name", text: $givenName)
                    TextField("Email", text: $email)
                }
                
                Section(header: Text("Change Password")) {
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                
                Button("Update") {
                    updateProfile()
                }
            }
            .navigationBarTitle("Update Profile")
            .onAppear {
//                loadCurrentUserData()
            }
        }
    }
    
    private func updateProfile() {
        guard newPassword == confirmPassword else {
            print("Passwords do not match")
            return
        }
        
        // Here you would typically handle the update logic, possibly updating credentials on a server.
        print("Profile update attempt for \(email)")
    }
}
#Preview {
    UpdateAccountView()
}
