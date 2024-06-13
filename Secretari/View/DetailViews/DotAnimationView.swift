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
    private let maxDots = 10
    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            Text(title)
            HStack(spacing: 0) {
                ForEach(0..<dotCount, id: \.self) { _ in
                    Text(".")
                }
            }
        }
        .font(.subheadline)
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
