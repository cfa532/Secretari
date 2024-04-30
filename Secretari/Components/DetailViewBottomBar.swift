//
//  DetailViewBottomBar.swift
//  Secretari
//
//  Created by 超方 on 2024/4/29.
//

import SwiftUI

struct DetailViewBottomBar: View {
    var body: some View {
        TabView{
            VStack {
                Text("Edit")
            }
            .tabItem { Label("Edit", systemImage: "pencil.line") }
            VStack {
                Text("Translate")
            }
            .tabItem { Label("Translate", systemImage: "bubble.left.and.text.bubble.right") }
            VStack {
                Text("Redo")
            }
            .tabItem { Label("Redo", systemImage: "arrow.triangle.2.circlepath") }        }
    }
}

#Preview {
    DetailViewBottomBar()
}
