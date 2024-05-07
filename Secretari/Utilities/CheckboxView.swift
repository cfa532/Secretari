//
//  CheckboxView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/7.
//

import SwiftUI

struct CheckboxView: View {
    var label: String
    @Binding var isChecked: Bool

    var body: some View {
        HStack {
            Image(systemName: isChecked ? "checkmark.square" : "square")
                .onTapGesture {
                    self.isChecked.toggle()
                }
            Text(label)
        }
        .foregroundColor(.primary) // Use the primary color or customize as needed
        .font(.system(size: 20)) // Customize the font size as needed
    }
}

#Preview {
    CheckboxView(label: "The line is checked", isChecked: .constant(true))
}
