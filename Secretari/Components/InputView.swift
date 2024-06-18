//
//  InputView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/28.
//

import SwiftUI

struct InputView: View {
    @Binding var text: String
    let title: String
    let placeHolder: String
    var isSecureField = false
    var required = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .foregroundStyle(.gray)
                    .fontWeight(.semibold)
                .font(.footnote)
                if required {
                    Text("*").foregroundStyle(.red)
                }
            }
            .padding(5)
            VStack() {
                if isSecureField {
                    SecureField(placeHolder, text: $text)
                        .font(.system(size: 18))
                } else {
                    TextField(placeHolder, text: $text)
                        .font(.system(size: 18))
                }
            }
            .padding(5)
            .background(Color(red: 0.99, green: 0.95, blue: 0.9).opacity(0.8))
            .cornerRadius(5)
        }
    }
}

#Preview {
    InputView(text: .constant(""), title: "Email address", placeHolder: "name@email")
}
