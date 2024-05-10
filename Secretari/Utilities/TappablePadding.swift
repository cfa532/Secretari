//
//  TappablePadding.swift
//  Secretari
//
//  Created by 超方 on 2024/5/10.
//

import SwiftUI

struct TappablePadding: ViewModifier {
  let insets: EdgeInsets
  let onTap: () -> Void
  
  func body(content: Content) -> some View {
    content
      .padding(insets)
      .contentShape(Rectangle())
      .onTapGesture {
        onTap()
      }
      .padding(insets.inverted)
  }
}

extension View {
  func tappablePadding(_ insets: EdgeInsets, onTap: @escaping () -> Void) -> some View {
    self.modifier(TappablePadding(insets: insets, onTap: onTap))
  }
}

extension EdgeInsets {
  var inverted: EdgeInsets {
    .init(top: -top, leading: -leading, bottom: -bottom, trailing: -trailing)
  }
}

//#Preview {
//    TappablePadding(insets: EdgeInsets()) {
//        return Void()
//    }
//}
