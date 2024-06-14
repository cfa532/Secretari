//
//  CheckboxView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/7.
//

import SwiftUI

struct CheckboxView: View {
    @Binding var label: String
    @Binding var isChecked: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isChecked ? "checkmark.square" : "square")
//                .resizable()
                .frame(width: 16, height: 16)
                .padding(4)
                .contentShape(Rectangle())
                .onTapGesture {
                    self.isChecked.toggle()
                }
            TextField(label, text: $label, axis: .vertical)
                .lineLimit(.max)
        }
        .foregroundColor(.primary) // Use the primary color or customize as needed
        .font(.system(size: 18)) // Customize the font size as needed
    }
}

#Preview {
    CheckboxView(label: .constant("The line is checked"), isChecked: .constant(true))
}
