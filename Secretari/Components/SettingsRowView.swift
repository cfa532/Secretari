//
//  SettingsRowView.swift
//  Secretari
//
//  Created by 超方 on 2024/5/29.
//

import SwiftUI

struct SettingsRowView: View {
    var imageName: String?
    var title: Text
    var tintColor: Color

    var body: some View {
        HStack {
            if let imageName = self.imageName {
            Image(systemName: imageName)
                .padding(.trailing, 10)      // Add some spacing between the image and the text
                .imageScale(.medium)
            }
            title
        }
        .foregroundStyle(tintColor)
    }
}

struct SettingsRowView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsRowView(imageName: "gear", title: Text("Settings"), tintColor: .blue)
            .previewLayout(.sizeThatFits)
    }
}
