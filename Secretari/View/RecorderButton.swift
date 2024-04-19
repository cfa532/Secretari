//
//  RoundButton.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/24.
//

import SwiftUI

struct RecorderButton: View {
    @Binding var isRecording: Bool
    let buttonAction: ()->Void
    
    var body: some View {
        HStack {
            Button(action: {
                isRecording.toggle()
                buttonAction()
            }, label: {
                Text(self.isRecording ? "Stop":"Start")
                    .padding(24)
                    .font(.title)
                    .background(Color.white)
                    .foregroundColor(.red)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            })
            if isRecording {
                TimeCounter()
            }
        }
    }
}

#Preview {
    //    RoundButton(image: Image(systemName: "stop.circle"))
    RecorderButton(isRecording: .constant(false), buttonAction: {})
}

/// a trick to fix the timerinvterval glitch.
struct TimeCounter: View {
    var body: some View {
        Image(systemName: "mic")
        let range = Date()...Date().addingTimeInterval(28800)
        Text(timerInterval: range, countsDown: false, showsHours: true)
    }
}
