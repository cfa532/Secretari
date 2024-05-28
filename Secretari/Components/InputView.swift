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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .foregroundStyle(.gray)
                    .fontWeight(.semibold)
                .font(.footnote)
                if required {
                    Text("*").foregroundStyle(.red)
//                    Spacer()
                }
            }
            if isSecureField {
                SecureField(placeHolder, text: $text)
                    .font(.system(size: 16))
            } else {
                TextField(placeHolder, text: $text)
                    .font(.system(size: 16))
            }
            Divider()
        }
    }
}

#Preview {
    InputView(text: .constant(""), title: "Email address", placeHolder: "name@email")
}
