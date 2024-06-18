//
//  DotAnimationView.swift
//  Secretari
//
//  Created by 超方 on 2024/6/13.
//

import SwiftUI

struct DotAnimationView: View {
    @State private var dotCount = 0
    let title: String
    private let maxDots = 5
    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    private let dotSize: CGFloat = 6
    
    var body: some View {
        HStack {
            Text(LocalizedStringKey(title))
            HStack(spacing: 0) {
                ForEach(0..<dotCount, id: \.self) { _ in
                    Circle()
                        .frame(width: dotSize, height: dotSize)
                        .padding(.trailing, 5)
                }
            }
        }
        .font(.callout)
        .onReceive(timer) { _ in
            updateDots()
        }
    }
    
    private func updateDots() {
        dotCount = (dotCount + 1) % (maxDots + 1)
    }
}

#Preview {
    DotAnimationView(title: "Working")
}
