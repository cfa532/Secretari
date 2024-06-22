//
//  RoundButton.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/24.
//

import SwiftUI

struct RecorderButton: View {
    @Binding var isRecording: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            Button(action: {
                isRecording.toggle()
                action()
            }, label: {
                Text(self.isRecording ? "Stop" : "Start")
                    .padding(24)
                    .font(.title)
                    .background(Color.white)
                    .foregroundStyle(isRecording ? .red.opacity(0.8) : .red)
                    .clipShape(Circle())
                    .shadow(radius: 5)
                    .overlay(
                        Circle()
                            .stroke(isRecording ? Color.red.opacity(0.8) : Color.clear, lineWidth: 4)
                    )
            })
            if isRecording {
                TimeCounter()
            }
        }
    }
}

#Preview {
    //    RoundButton(image: Image(systemName: "stop.circle"))
    RecorderButton(isRecording: .constant(false), action: {})
}

/// a trick to fix the timerinvterval glitch, which doesn't update the text somehow.
struct TimeCounter: View {
    var body: some View {
        Image(systemName: "mic")
        let d = Date()
        let range = d...d.addingTimeInterval(28800)
        Text(timerInterval: range, countsDown: false, showsHours: true)
    }
}
