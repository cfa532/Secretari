//
//  CheckboxView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/7.
//

import SwiftUI

// Custom checkbox view that combines a checkmark image with a text field.
struct CheckboxView: View {
    @Binding var label: String
    @Binding var isChecked: Bool
    
    var body: some View {
        HStack {
            // Display a checkmark image if checked, otherwise a square.
            Image(systemName: isChecked ? "checkmark.square" : "square")
                .frame(width: 16, height: 16)
                .padding(4)
                .contentShape(Rectangle())
                .onTapGesture {
                    self.isChecked.toggle()
                }
            // Text field for the label, allowing multiple lines.
            TextField(label, text: $label, axis: .vertical)
                .lineLimit(.max)
        }
        .foregroundColor(.primary)  // Use the primary color or customize as needed
        .font(.system(size: 18))    // Customize the font size as needed
    }
}

#Preview {
    CheckboxView(label: .constant("The line is checked"), isChecked: .constant(true))
}
