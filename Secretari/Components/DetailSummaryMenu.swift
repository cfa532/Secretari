//
//  DetailSummaryMenu.swift
//  Secretari
//
//  Created by 超方 on 2024/4/30.
//

import SwiftUI

struct DetailSummaryMenu: View {
    var body: some View {
        Menu(content: {
            Button {
                print("show share meun")
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button {
                print("show raw transcript")
            } label: {
                Label("Transcript", systemImage: "text.word.spacing")
            }
            Button {
                print("edit summary")
            } label: {
                Label("Edit", systemImage: "pencil.line")
            }
            Menu("Translations", systemImage: "square.fill.text.grid.1x2") {
                Button {
                    print("Translate to English")
                } label: {
                    Text("English")
                }
                Button {
                    print("Translate to English")
                } label: {
                    Text("English")
                }
            }
        }, label: {
            Image(systemName: "ellipsis")
//                .resizable()
        })
    }
}

#Preview {
    DetailSummaryMenu()
}
